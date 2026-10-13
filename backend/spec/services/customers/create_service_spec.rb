require "rails_helper"

RSpec.describe Customers::CreateService do
  let(:project) { create(:project) }

  it "creates a new customer when no row matches external_id" do
    customer = described_class.new(project: project, attrs: { external_id: "cust-1", name: "Jane" }).call
    expect(customer).to be_a(Customer)
    expect(customer.external_id).to eq("cust-1")
    expect(customer.name).to eq("Jane")
    expect(Customer.where(project_id: project.id, external_id: "cust-1").count).to eq(1)
  end

  it "updates the existing customer's known attrs instead of creating a second row" do
    create(:customer, project: project, external_id: "cust-1", name: "Old Name")

    customer = described_class.new(project: project, attrs: { external_id: "cust-1", name: "New Name" }).call

    expect(customer.name).to eq("New Name")
    expect(Customer.where(project_id: project.id, external_id: "cust-1").count).to eq(1)
  end

  it "raises on field external_id when external_id is blank" do
    expect { described_class.new(project: project, attrs: { external_id: "" }).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "external_id"))
    end
  end

  it "raises on field external_id when external_id is missing" do
    expect { described_class.new(project: project, attrs: {}).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "external_id"))
    end
  end

  it "merges an explicit metadata hash into the customer's metadata" do
    customer = described_class.new(project: project, attrs: { external_id: "cust-1", metadata: { tier: "gold" } }).call
    expect(customer.metadata.to_h).to eq({ "tier" => "gold" })
  end

  it "treats any key outside external_id/known attrs/metadata as a custom attribute" do
    customer = described_class.new(project: project, attrs: { external_id: "cust-1", loyalty_tier: "gold" }).call
    expect(customer.metadata.to_h).to eq({ "loyalty_tier" => "gold" })
  end

  it "lets a flat inline key win over the same key in an explicit metadata hash" do
    customer = described_class.new(project: project, attrs: { external_id: "cust-1", metadata: { tier: "silver" }, tier: "gold" }).call
    expect(customer.metadata.to_h).to eq({ "tier" => "gold" })
  end

  it "merges new custom attrs into the existing metadata on update, keeping untouched keys" do
    create(:customer, project: project, external_id: "cust-1", metadata: { tier: "gold" })

    customer = described_class.new(project: project, attrs: { external_id: "cust-1", source: "referral" }).call

    expect(customer.metadata.to_h).to eq({ "tier" => "gold", "source" => "referral" })
  end

  it "overwrites an existing metadata key on update" do
    create(:customer, project: project, external_id: "cust-1", metadata: { tier: "gold" })

    customer = described_class.new(project: project, attrs: { external_id: "cust-1", tier: "platinum" }).call

    expect(customer.metadata.to_h).to eq({ "tier" => "platinum" })
  end

  it "leaves metadata untouched when no custom attrs are submitted" do
    create(:customer, project: project, external_id: "cust-1", metadata: { tier: "gold" })

    customer = described_class.new(project: project, attrs: { external_id: "cust-1", name: "Jane" }).call

    expect(customer.metadata.to_h).to eq({ "tier" => "gold" })
  end

  it "raises a ValidationError on a model validation failure" do
    attrs = { external_id: "cust-1", date_of_birth: (Date.today + 1).iso8601 }
    expect { described_class.new(project: project, attrs: attrs).call }.to raise_error(ValidationError)
  end
end
