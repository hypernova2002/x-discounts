# frozen_string_literal: true

require "securerandom"

# The single shared code that used to live at discounts.kind_config->>'code' becomes
# its own coupon_codes row (unbound, max_redemptions from the discount's own
# max_redemptions if it had one) — then the old redemptions rows (which, per code
# review, were written on every coupon redemption but never actually read anywhere)
# get relinked to it, since every Redemption now requires a coupon_code_id.
Sequel.migration do
  up do
    from(:discounts).where(kind: "coupon").each do |d|
      config = d[:kind_config] || {}
      code = config["code"]
      next unless code

      coupon_code_id = from(:coupon_codes).insert(
        discount_id: d[:id],
        project_id: d[:project_id],
        public_id: "cpn_#{SecureRandom.alphanumeric(16).downcase}",
        code: code,
        max_redemptions: d[:max_redemptions] || 999_999,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      )

      from(:redemptions).where(discount_id: d[:id]).update(coupon_code_id: coupon_code_id)

      config.delete("code")
      from(:discounts).where(id: d[:id]).update(kind_config: Sequel.pg_jsonb(config))
    end

    from(:redemptions).where(coupon_code_id: nil).delete
  end

  down do
    raise Sequel::Error, "not reversible"
  end
end
