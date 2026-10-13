require "rails_helper"

RSpec.describe CustomerRequest do
  it "accepts just a required external_id" do
    expect { described_class.new(external_id: "cust-1") }.not_to raise_error
  end

  it "rejects a missing external_id" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty external_id" do
    expect { described_class.new(external_id: "") }.to raise_error(Dry::Struct::Error)
  end

  %i[name email phone_number country date_of_birth].each do |field|
    it "omits #{field} by default" do
      expect(described_class.new(external_id: "cust-1").attributes.key?(field)).to eq(false)
    end

    it "accepts an explicit nil #{field}" do
      expect { described_class.new(external_id: "cust-1", field => nil) }.not_to raise_error
    end
  end

  it "accepts a full set of optional attributes" do
    record = described_class.new(
      external_id: "cust-1", name: "Jane Doe", email: "jane@example.com", phone_number: "+15551234567",
      country: "US", date_of_birth: "1990-01-01", marketing_opt_in: true, metadata: { vip: true }
    )
    expect(record.name).to eq("Jane Doe")
    expect(record.marketing_opt_in).to eq(true)
    expect(record.metadata).to eq({ vip: true })
  end

  it "rejects a non-boolean marketing_opt_in" do
    expect { described_class.new(external_id: "cust-1", marketing_opt_in: "yes") }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a non-hash metadata" do
    expect { described_class.new(external_id: "cust-1", metadata: "not a hash") }.to raise_error(Dry::Struct::Error)
  end
end
