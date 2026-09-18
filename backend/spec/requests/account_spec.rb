require "rails_helper"
require "openapi_helper"

RSpec.describe "Account API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/account" do
    get "Show the current account" do
      tags "Account"
      operationId "getAccount"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the account" do
        schema Schemas::Account

        run_test!
      end
    end

    patch "Update the current account" do
      tags "Account"
      operationId "updateAccount"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: { type: :object, properties: { name: { type: :string } } } }
      }

      response 200, "account updated" do
        schema Schemas::Account
        let(:request_body) { { name: "Renamed Co" } }

        run_test!
      end

      response 403, "not an account admin" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { name: "Renamed Co" } }

        run_test!
      end
    end
  end
end
