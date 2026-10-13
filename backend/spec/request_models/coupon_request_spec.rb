require "rails_helper"

RSpec.describe CouponRequest do
  it "accepts an empty body (no codes, added later)" do
    record = described_class.new({})
    expect(record.max_redemptions).to eq(1)
  end

  %i[issued_from issued_until valid_from valid_until design_html code customer_id prefix suffix].each do |field|
    it "omits #{field} by default and accepts an explicit nil" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
      expect { described_class.new(field => nil) }.not_to raise_error
    end
  end

  it "accepts an explicit count" do
    expect(described_class.new(count: 5).count).to eq(5)
  end

  it "accepts an array of customer_ids" do
    expect(described_class.new(customer_ids: %w[cust_1 cust_2]).customer_ids).to eq(%w[cust_1 cust_2])
  end

  it "defaults max_redemptions to 1" do
    expect(described_class.new({}).max_redemptions).to eq(1)
  end

  it "rejects a zero max_redemptions" do
    expect { described_class.new(max_redemptions: 0) }.to raise_error(Dry::Struct::Error)
  end

  it "accepts a present design_html" do
    expect(described_class.new(design_html: "<p>Save 10%</p>").design_html).to eq("<p>Save 10%</p>")
  end
end
