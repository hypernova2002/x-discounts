# frozen_string_literal: true

class Discount < Sequel::Model
  include ConditionTreeValidatable
  include PublicIdentifiable
  include BoundedFieldValidatable

  KINDS = %w[promotion coupon loyalty].freeze
  KEY_FORMAT = /\A[a-zA-Z0-9_.-]+\z/
  PUBLIC_ID_PREFIX = "disc"

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :project
  many_to_one :campaign
  one_to_many :discount_effects
  one_to_many :discount_stacking_compatibilities
  one_to_many :coupon_codes

  many_to_many :compatible_discounts,
                class: :Discount,
                join_table: :discount_stacking_compatibilities,
                left_key: :discount_id,
                right_key: :compatible_discount_id

  add_association_dependencies discount_effects: :destroy,
                                discount_stacking_compatibilities: :destroy,
                                coupon_codes: :destroy

  def before_destroy
    DiscountStackingCompatibility.where(compatible_discount_id: id).destroy
    super
  end

  def validate
    super
    validates_presence [:project_id, :campaign_id, :kind, :name, :key]
    validates_includes KINDS, :kind, allow_missing: true
    validates_utf8_length :name, max: 1000
    validates_utf8_length :key, max: 255
    validates_unique [:project_id, :key] unless errors[:key]
    validates_format KEY_FORMAT, :key, message: "may only contain letters, numbers, underscores, hyphens, and periods", allow_nil: true
    validates_boolean :stackable
    validates_boolean :refundable
    validates_boolean :enabled
    validates_bounded_number :max_redemptions, min: 1, max: 1_000_000, integer_only: true
    validates_bounded_number :max_redemptions_per_customer, min: 1, max: 1_000_000, integer_only: true
    validates_bounded_number :max_redemptions_per_day, min: 1, max: 1_000_000, integer_only: true
    validates_bounded_number :max_redemption_amount, min: 0, max: 100_000_000
    validates_bounded_number :max_redemption_amount_per_day, min: 0, max: 100_000_000
    validates_bounded_number :max_redemption_amount_per_customer, min: 0, max: 100_000_000
    validate_kind_config

    if eligibility_condition && !eligibility_condition.empty?
      condition_errors = []
      valid_condition_tree?(eligibility_condition, condition_errors)
      condition_errors.each { |msg| errors.add(:eligibility_condition, msg) }
    end
  end

  # kind_config holds whatever's specific to `kind` (promotion/coupon/loyalty) —
  # small enough (a handful of scalars each, no children of their own) that a shared
  # jsonb column beats three near-empty tables. Dates are stored as the ISO strings
  # the request sent; these accessors parse on read so callers get real Time objects,
  # same as when these lived on typed columns.
  def active_from
    parse_time(kind_config["active_from"])
  end

  def active_until
    parse_time(kind_config["active_until"])
  end

  def issued_from
    parse_time(kind_config["issued_from"])
  end

  def issued_until
    parse_time(kind_config["issued_until"])
  end

  def valid_from
    parse_time(kind_config["valid_from"])
  end

  def valid_until
    parse_time(kind_config["valid_until"])
  end

  def points_expire_after_days
    kind_config["points_expire_after_days"]
  end

  # Coupon-only: the customer-facing "design" (spec section 5). design_html is
  # already sanitized before it's ever written here (see Coupons::CreateService/
  # UpdateService) — this reader doesn't re-sanitize, it just surfaces what's
  # stored. The image's own bytes live on local disk (Coupons::AttachDesignImageService,
  # same bespoke pattern as GiftShopItem's photo), keyed by this discount's own
  # public_id — only the upload metadata lives in kind_config.
  def design_html
    kind_config["design_html"]
  end

  def design_image_filename
    kind_config["design_image_filename"]
  end

  def design_image_content_type
    kind_config["design_image_content_type"]
  end

  def design_image_byte_size
    kind_config["design_image_byte_size"]
  end

  def design_image?
    design_image_filename.present?
  end

  def design_image_path
    return nil unless design_image?

    Rails.root.join("storage", "coupon_designs", "#{public_id}#{File.extname(design_image_filename)}")
  end

  # Refund-aware, same philosophy as CouponCode#redemption_count — a refunded
  # usage no longer counts. OrderDiscount (not Redemption, which only exists for
  # coupon-kind discounts) is the universal per-discount-application row across
  # all three kinds, so this works for promotion/loyalty discounts too. Delegates
  # to OrderDiscount#refunded? rather than re-deriving it, since loyalty rows are
  # refunded via a ledger clawback, not a DiscountRefund record like the other
  # two kinds — getting that distinction right belongs in one place.
  def redemption_count
    OrderDiscount.where(discount_id: id).all.count { |od| !od.refunded? }
  end

  # Loyalty-only. Total points ever credited to a customer via this discount —
  # every LoyaltyPointLot it earned, regardless of how much of that has since
  # been spent or clawed back.
  def points_earned
    return 0 unless kind == "loyalty"

    LoyaltyPointLot.where(discount_id: id).sum(:points) || 0
  end

  # Loyalty-only. How many of this discount's earned points have actually been
  # spent by a customer (checkout or gift shop) — ledger entries of kind
  # "spend" only, not "clawback" (a refund reversing the original earn is not
  # a redemption). delta is stored negative, so this negates the sum.
  def points_redeemed
    return 0 unless kind == "loyalty"

    lot_ids = LoyaltyPointLot.where(discount_id: id).select(:id)
    -(LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: lot_ids, kind: "spend").sum(:delta) || 0)
  end

  # "Currently running" for a promotion/loyalty discount — enabled and within its
  # own active_from/active_until window, mirroring Campaign#active?'s date-window
  # shape. Coupon uses valid_from/valid_until instead, so this only makes sense
  # for the two kinds that share active_from/active_until.
  def active?(now = Time.now.utc)
    enabled && (active_from.nil? || active_from <= now) && (active_until.nil? || now <= active_until)
  end

  private

  def parse_time(value)
    value ? Time.parse(value).utc : nil
  end

  # kind_config's own free-text/count sub-fields — the date strings and
  # nested design_image_byte_size are left alone here, same as the rest of
  # kind_config's shape, since this pass doesn't add jsonb structural validation.
  def validate_kind_config
    cfg = (kind_config || {}).to_h.stringify_keys
    add_utf8_length_errors(:kind_config, cfg["design_html"], max: 10_000)
    add_utf8_length_errors(:kind_config, cfg["design_image_filename"], max: 255)
    add_utf8_length_errors(:kind_config, cfg["design_image_content_type"], max: 255)
    add_bounded_number_errors(:kind_config, cfg["points_expire_after_days"], min: 0, max: 10_000, integer_only: true)
  end
end
