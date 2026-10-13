require "rails_helper"

RSpec.describe CouponDiscountUpdateRequest do
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

    it "accepts an explicit #{field}" do
      expect { described_class.new(field => "value") }.not_to raise_error
    end
  end

  %i[stackable refundable enabled].each do |field|
    it "omits #{field} when not sent" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
    end

    it "rejects an explicit nil #{field} (not nullable)" do
      expect { described_class.new(field => nil) }.to raise_error(Dry::Struct::Error)
    end

    it "accepts an explicit #{field}" do
      expect { described_class.new(field => true) }.not_to raise_error
    end
  end

  it "omits eligibility_condition when not sent and accepts an explicit nil (clearing it)" do
    expect(described_class.new({}).attributes.key?(:eligibility_condition)).to eq(false)
    record = described_class.new(eligibility_condition: nil)
    expect(record.attributes.key?(:eligibility_condition)).to eq(true)
  end

  it "accepts a present coupon sub-struct" do
    record = described_class.new(coupon: { max_redemptions: 1 })
    expect(record.coupon).to be_a(CouponRequest)
  end

  # Known gap: coupon isn't nullable (unlike eligibility_condition), but an explicit
  # null currently crashes with a raw NoMethodError (JsonModel::Schema#new calls
  # #transform_keys on the input before Dry::Struct gets a chance to validate it) —
  # NoMethodError isn't in ApplicationController's rescue_from list, so this reaches
  # the client as an uncaught 500 instead of a normal 422. Documenting the current
  # behavior here rather than silently asserting a Dry::Struct::Error that doesn't
  # actually happen; left as a known gap to fix separately.
  it "currently crashes (NoMethodError) on an explicit nil coupon, instead of a clean validation error" do
    expect { described_class.new(coupon: nil) }.to raise_error(NoMethodError, /transform_keys/)
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

    it "rejects a non-integer #{field}" do
      expect { described_class.new(field => "ten") }.to raise_error(Dry::Struct::Error)
    end
  end

  %i[max_redemption_amount max_redemption_amount_per_day max_redemption_amount_per_customer].each do |field|
    it "accepts an explicit nil #{field} (clearing the limit)" do
      expect { described_class.new(field => nil) }.not_to raise_error
    end

    it "accepts a float #{field}" do
      expect { described_class.new(field => 10.5) }.not_to raise_error
    end
  end
end
