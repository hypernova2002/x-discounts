require "rails_helper"
require "openapi_helper"

RSpec.describe "Customers API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  path "/api/v1/customers" do
    post "Create (or upsert) a customer" do
      tags "Customers"
      operationId "createCustomer"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::CustomerCreateRequest }
      }

      response 201, "customer created" do
        schema Schemas::Customer
        let(:request_body) { { external_id: "cust1", name: "Jane Doe", email: "jane@example.com", marketing_opt_in: true } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("Jane Doe")
          expect(body["marketing_opt_in"]).to eq(true)
        end
      end

      response 201, "resubmitting the same external_id updates the existing customer" do
        schema Schemas::Customer

        before { create(:customer, project: project, external_id: "cust1", name: "Old Name") }

        let(:request_body) { { external_id: "cust1", name: "New Name" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("New Name")
          expect(Customer.where(project_id: project.id, external_id: "cust1").count).to eq(1)
        end
      end

      response 422, "missing external_id" do
        schema Schemas::Error
        let(:request_body) { { name: "No external id" } }

        run_test!
      end
    end
  end

  path "/api/v1/customers/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show a customer" do
      tags "Customers"
      operationId "getCustomer"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the customer" do
        schema Schemas::Customer
        let(:id) { create(:customer, project: project).public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "cust_nonexistent" }

        run_test!
      end
    end
  end
end
