require "rails_helper"

RSpec.describe CouponDiscountRequest do
  let(:valid_attrs) { { name: "10% Off", campaign_id: "camp_1", coupon: {} } }

  it "accepts just the required attributes" do
    record = described_class.new(valid_attrs)
    expect(record.stackable).to eq(false)
    expect(record.refundable).to eq(true)
    expect(record.enabled).to eq(true)
  end

  it "omits key by default and accepts an explicit nil (auto-generated)" do
    expect(described_class.new(valid_attrs).attributes.key?(:key)).to eq(false)
    expect { described_class.new(valid_attrs.merge(key: nil)) }.not_to raise_error
  end

  it "rejects an empty key" do
    expect { described_class.new(valid_attrs.merge(key: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing campaign_id" do
    expect { described_class.new(valid_attrs.except(:campaign_id)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing coupon sub-struct" do
    expect { described_class.new(valid_attrs.except(:coupon)) }.to raise_error(Dry::Struct::Error)
  end

  it "builds coupon as a CouponRequest instance" do
    expect(described_class.new(valid_attrs).coupon).to be_a(CouponRequest)
  end

  it "defaults stackable/refundable/enabled and accepts explicit overrides" do
    record = described_class.new(valid_attrs.merge(stackable: true, refundable: false, enabled: false))
    expect(record.stackable).to eq(true)
    expect(record.refundable).to eq(false)
    expect(record.enabled).to eq(false)
  end

  it "omits eligibility_condition by default and accepts a present one" do
    expect(described_class.new(valid_attrs).attributes.key?(:eligibility_condition)).to eq(false)
    condition = { entity: "cart", key: "subtotal", operator: "gte", value: 50 }
    record = described_class.new(valid_attrs.merge(eligibility_condition: condition))
    expect(record.eligibility_condition).to be_a(ConditionNode)
  end

  it "omits effects by default and accepts an explicit list" do
    expect(described_class.new(valid_attrs).attributes.key?(:effects)).to eq(false)
    effects = [{ effect_type: "percentage_off", scope: "cart", config: { percentage: 10 } }]
    record = described_class.new(valid_attrs.merge(effects: effects))
    expect(record.effects.first).to be_a(DiscountEffectRequest)
  end

  it "omits every max_redemptions/max_redemption_amount limit by default" do
    record = described_class.new(valid_attrs)
    %i[max_redemptions max_redemptions_per_customer max_redemptions_per_day
       max_redemption_amount max_redemption_amount_per_day max_redemption_amount_per_customer].each do |field|
      expect(record.attributes.key?(field)).to eq(false)
    end
  end
end
