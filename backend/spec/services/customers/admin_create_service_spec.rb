require "rails_helper"

RSpec.describe Customers::AdminCreateService do
  let(:project) { create(:project) }

  it "creates a customer from the request's fields" do
    request = CustomerRequest.new(external_id: "cust-1", name: "Jane", email: "jane@example.com")
    customer = described_class.new(project: project, request: request).call

    expect(customer.external_id).to eq("cust-1")
    expect(customer.name).to eq("Jane")
    expect(customer.email).to eq("jane@example.com")
  end

  it "defaults marketing_opt_in to false when not given" do
    request = CustomerRequest.new(external_id: "cust-1")
    customer = described_class.new(project: project, request: request).call
    expect(customer.marketing_opt_in).to eq(false)
  end

  it "honors an explicit marketing_opt_in: true" do
    request = CustomerRequest.new(external_id: "cust-1", marketing_opt_in: true)
    customer = described_class.new(project: project, request: request).call
    expect(customer.marketing_opt_in).to eq(true)
  end

  it "raises on field external_id (remapped from the compound unique key) for a duplicate external_id" do
    create(:customer, project: project, external_id: "cust-1")
    request = CustomerRequest.new(external_id: "cust-1")

    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to contain_exactly(hash_including(field: "external_id"))
    end
  end

  it "doesn't collide across different projects" do
    other_project = create(:project)
    create(:customer, project: other_project, external_id: "cust-1")
    request = CustomerRequest.new(external_id: "cust-1")

    expect { described_class.new(project: project, request: request).call }.not_to raise_error
  end

  it "raises a plain ValidationError for a non-uniqueness validation failure" do
    request = CustomerRequest.new(external_id: "cust-1", date_of_birth: (Date.today + 1).iso8601)
    expect { described_class.new(project: project, request: request).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "date_of_birth"))
    end
  end
end
