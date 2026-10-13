require "rails_helper"

RSpec.describe CustomAttributes::CreateService do
  let(:project) { create(:project) }

  it "creates an attribute with the given fields" do
    request = CustomAttributeRequest.new(entity: "customer", key: "loyalty_tier", data_type: "string")
    attribute = described_class.new(project: project, request: request).call

    expect(attribute.entity).to eq("customer")
    expect(attribute.key).to eq("loyalty_tier")
    expect(attribute.data_type).to eq("string")
  end

  it "raises a ValidationError when (project, entity, key) collides with an existing attribute" do
    create(:custom_attribute, project: project, entity: "customer", key: "loyalty_tier")
    request = CustomAttributeRequest.new(entity: "customer", key: "loyalty_tier", data_type: "number")

    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError)
  end

  it "doesn't collide when the entity differs" do
    create(:custom_attribute, project: project, entity: "customer", key: "tier")
    request = CustomAttributeRequest.new(entity: "cart", key: "tier", data_type: "string")

    expect { described_class.new(project: project, request: request).call }.not_to raise_error
  end
end
