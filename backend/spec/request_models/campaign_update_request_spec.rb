require "rails_helper"

RSpec.describe CampaignUpdateRequest do
  it "accepts an empty body (nothing to update)" do
    expect { described_class.new({}) }.not_to raise_error
  end

  it "rejects an empty name" do
    expect { described_class.new(name: "") }.to raise_error(Dry::Struct::Error)
  end

  %i[name enabled archived].each do |field|
    value = field == :name ? "New Name" : true

    it "omits #{field} when not sent" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
    end

    it "rejects an explicit nil #{field} (not nullable, unlike valid_from/valid_until)" do
      expect { described_class.new(field => nil) }.to raise_error(Dry::Struct::Error)
    end

    it "accepts an explicit #{field}" do
      expect { described_class.new(field => value) }.not_to raise_error
    end
  end

  %i[valid_from valid_until].each do |field|
    it "omits #{field} when not sent" do
      expect(described_class.new({}).attributes.key?(field)).to eq(false)
    end

    it "accepts an explicit nil #{field} (clearing it)" do
      record = described_class.new(field => nil)
      expect(record.attributes.key?(field)).to eq(true)
    end
  end

  it "rejects a non-boolean enabled" do
    expect { described_class.new(enabled: "yes") }.to raise_error(Dry::Struct::Error)
  end
end
