require "rails_helper"

RSpec.describe Coupons::CreateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def build_request(**overrides)
    CouponDiscountRequest.new({ name: "Save 10", campaign_id: campaign.public_id, coupon: {} }.merge(overrides))
  end

  it "builds a coupon-kind discount with the request's own fields" do
    request = build_request(stackable: true, refundable: false, enabled: false)
    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.kind).to eq("coupon")
    expect(discount.name).to eq("Save 10")
    expect(discount.stackable).to eq(true)
    expect(discount.refundable).to eq(false)
    expect(discount.enabled).to eq(false)
    expect(discount.campaign_id).to eq(campaign.id)
  end

  it "folds the coupon sub-request's dates into kind_config" do
    request = build_request(coupon: { valid_from: "2026-01-01T00:00:00Z", valid_until: "2026-12-31T00:00:00Z" })
    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.valid_from).to eq(Time.parse("2026-01-01T00:00:00Z"))
    expect(discount.valid_until).to eq(Time.parse("2026-12-31T00:00:00Z"))
  end

  it "uses an explicit key as-is" do
    request = build_request(key: "my-key")
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.key).to eq("my-key")
  end

  it "generates a key from name when omitted" do
    request = build_request(name: "Summer Sale")
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.key).to eq("summer-sale")
  end

  it "sanitizes design_html before storing it" do
    request = build_request(coupon: { design_html: "<p>Save <script>alert(1)</script>10%</p>" })
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.kind_config["design_html"]).to eq("<p>Save alert(1)10%</p>")
  end

  it "saves the requested effects onto the discount" do
    request = build_request(effects: [{ effect_type: "percentage_off", scope: "cart", config: { percentage: 15 } }])
    discount = described_class.new(project: project, request: request, campaign: campaign).call

    expect(discount.discount_effects.size).to eq(1)
    expect(discount.discount_effects.first.effect_type).to eq("percentage_off")
  end

  # Known gap: save_effects computes `effect_req.typed_config.to_h` (which re-validates
  # the effect's config against its own Dry::Struct, e.g. PercentageOffConfigRequest's
  # lteq: 100) *before* entering save_effect's own rescue block, so a config that fails
  # that re-validation raises a raw Dry::Struct::Error here instead of the intended
  # ValidationError with an "effects[0]." field prefix. Still caught cleanly at the
  # controller layer (ApplicationController's own rescue_from Dry::Struct::Error), just
  # with a generic field: "base" instead of pointing at the actual effect — documenting
  # actual behavior rather than asserting the unreached intended one.
  it "currently raises a raw Dry::Struct::Error for a config that fails its own type's validation" do
    request = build_request(effects: [{ effect_type: "percentage_off", scope: "cart", config: { percentage: 150 } }])

    expect { described_class.new(project: project, request: request, campaign: campaign).call }.to raise_error(Dry::Struct::Error, /lteq/)
  end

  it "raises on field effects[0].* for an effect that fails DiscountEffect's own model validation" do
    request = build_request(effects: [{ effect_type: "percentage_off", scope: "line_item", config: { percentage: 10 } }])

    expect { described_class.new(project: project, request: request, campaign: campaign).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: a_string_matching(/\Aeffects\[0\]\./)))
    end
  end

  it "generates initial codes when the coupon sub-request asks for them" do
    request = build_request(coupon: { count: 3 })
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.coupon_codes.size).to eq(3)
  end

  it "generates no codes when the coupon sub-request doesn't ask for any" do
    request = build_request
    discount = described_class.new(project: project, request: request, campaign: campaign).call
    expect(discount.coupon_codes).to be_empty
  end

  it "raises a ValidationError when the key collides with an existing discount in the project" do
    create(:discount, project: project, campaign: campaign, key: "taken")
    request = build_request(key: "taken")

    expect { described_class.new(project: project, request: request, campaign: campaign).call }.to raise_error(ValidationError)
  end
end
