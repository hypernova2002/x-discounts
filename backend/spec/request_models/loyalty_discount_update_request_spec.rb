require "rails_helper"

RSpec.describe LoyaltyDiscountUpdateRequest do
  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  %i[key name campaign_id].each do |field|
    it "omits #{field} when not sent" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
    end

    it "rejects an empty #{field}" do
      expect { described_class.new(field => "") }.to raise_error(Dry::Struct::Error)
    end

    it "rejects an explicit nil #{field} (not nullable)" do
      expect { described_class.new(field => nil) }.to raise_error(Dry::Struct::Error)
    end
  end

  %i[stackable refundable enabled].each do |field|
    it "omits #{field} when not sent" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
    end

    it "rejects an explicit nil #{field} (not nullable)" do
      expect { described_class.new(field => nil) }.to raise_error(Dry::Struct::Error)
    end
  end

  it "omits eligibility_condition when not sent and accepts an explicit nil (clearing it)" do
    expect(described_class.new({}).attributes.key?(:eligibility_condition)).to eq(false)
    record = described_class.new(eligibility_condition: nil)
    expect(record.attributes.key?(:eligibility_condition)).to eq(true)
  end

  it "accepts a present loyalty sub-struct" do
    record = described_class.new(loyalty: { active_from: "2026-01-01T00:00:00Z" })
    expect(record.loyalty).to be_a(LoyaltyRequest)
  end

  # Known gap: same as CouponDiscountUpdateRequest#coupon — see that spec's comment.
  it "currently crashes (NoMethodError) on an explicit nil loyalty, instead of a clean validation error" do
    expect { described_class.new(loyalty: nil) }.to raise_error(NoMethodError, /transform_keys/)
  end

  it "rejects a loyalty sub-struct missing its own required active_from" do
    expect { described_class.new(loyalty: {}) }.to raise_error(Dry::Struct::Error)
  end

  it "omits effects when not sent and accepts an explicit nil (clearing them)" do
    expect(described_class.new({}).attributes.key?(:effects)).to eq(false)
    record = described_class.new(effects: nil)
    expect(record.attributes.key?(:effects)).to eq(true)
  end

  %i[max_redemptions max_redemptions_per_customer max_redemptions_per_day].each do |field|
    it "accepts an explicit nil #{field} (clearing the limit)" do
      expect { described_class.new(field => nil) }.not_to raise_error
    end
  end

  %i[max_redemption_amount max_redemption_amount_per_day max_redemption_amount_per_customer].each do |field|
    it "accepts an explicit nil #{field} (clearing the limit)" do
      expect { described_class.new(field => nil) }.not_to raise_error
    end
  end
end
