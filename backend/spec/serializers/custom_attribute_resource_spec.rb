require "rails_helper"

RSpec.describe CustomAttributeResource do
  it "renders the attribute's fields" do
    attribute = create(:custom_attribute, entity: "customer", key: "loyalty_tier", data_type: "string")
    hash = described_class.new(attribute).to_h

    expect(hash["id"]).to eq(attribute.public_id)
    expect(hash["entity"]).to eq("customer")
    expect(hash["key"]).to eq("loyalty_tier")
    expect(hash["data_type"]).to eq("string")
  end
end
