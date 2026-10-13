require "rails_helper"

RSpec.describe Coupons::UpdateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) do
    create(:discount, project: project, campaign: campaign, kind: "coupon", name: "Old Name",
                       kind_config: { valid_until: "2026-12-31T00:00:00Z" }, max_redemptions: 10)
  end

  it "updates name only when the request includes it" do
    request = CouponDiscountUpdateRequest.new(name: "New Name")
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.name).to eq("New Name")
  end

  it "leaves name untouched when the request doesn't include it" do
    request = CouponDiscountUpdateRequest.new(max_redemptions: 20)
    updated = described_class.new(discount: discount, request: request).call
    expect(updated.name).to eq("Old Name")
    expect(updated.max_redemptions).to eq(20)
  end

  it "doesn't touch kind_config at all when the request has no coupon: key" do
    discount.update(kind_config: discount.kind_config.merge("design_image_filename" => "mug.png"))
    request = CouponDiscountUpdateRequest.new(name: "New Name")

    updated = described_class.new(discount: discount, request: request).call

    expect(updated.kind_config["valid_until"]).to eq("2026-12-31T00:00:00Z")
    expect(updated.kind_config["design_image_filename"]).to eq("mug.png")
  end

  it "preserves a previously-attached design image's metadata when an unrelated coupon field changes" do
    discount.update(kind_config: discount.kind_config.merge(
                       "design_image_filename" => "mug.png", "design_image_content_type" => "image/png", "design_image_byte_size" => 1234
                     ))
    request = CouponDiscountUpdateRequest.new(coupon: { valid_until: "2027-01-01T00:00:00Z" })

    updated = described_class.new(discount: discount, request: request).call

    expect(updated.kind_config["valid_until"]).to eq("2027-01-01T00:00:00Z")
    expect(updated.kind_config["design_image_filename"]).to eq("mug.png")
    expect(updated.kind_config["design_image_content_type"]).to eq("image/png")
    expect(updated.kind_config["design_image_byte_size"]).to eq(1234)
  end

  it "destroys and recreates every effect when the request includes effects:" do
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 5 })
    old_effect_id = discount.discount_effects.first.id

    request = CouponDiscountUpdateRequest.new(effects: [{ effect_type: "fixed_amount_off", scope: "cart", config: { amount: 10, currency: "USD" } }])
    updated = described_class.new(discount: discount, request: request).call

    expect(updated.discount_effects.size).to eq(1)
    expect(updated.discount_effects.first.id).not_to eq(old_effect_id)
    expect(updated.discount_effects.first.effect_type).to eq("fixed_amount_off")
    expect(DiscountEffect[old_effect_id]).to be_nil
  end

  it "leaves existing effects untouched when the request doesn't include effects:" do
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 5 })
    request = CouponDiscountUpdateRequest.new(name: "New Name")

    updated = described_class.new(discount: discount, request: request).call
    expect(updated.discount_effects.size).to eq(1)
  end

  it "raises a ValidationError on a model validation failure" do
    request = CouponDiscountUpdateRequest.new(name: "a" * 1001)
    expect { described_class.new(discount: discount, request: request).call }.to raise_error(ValidationError)
  end
end
