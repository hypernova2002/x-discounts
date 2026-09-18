# frozen_string_literal: true

class Discount < Sequel::Model
  include ConditionTreeValidatable
  include PublicIdentifiable

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
    validates_unique [:project_id, :key]
    validates_format KEY_FORMAT, :key, message: "may only contain letters, numbers, underscores, hyphens, and periods", allow_nil: true

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

  private

  def parse_time(value)
    value ? Time.parse(value).utc : nil
  end
end
