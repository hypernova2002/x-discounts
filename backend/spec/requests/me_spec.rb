require "rails_helper"
require "openapi_helper"

RSpec.describe "Me API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/me" do
    get "Current identity" do
      tags "Me"
      operationId "getMe"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the current identity" do
        schema Schemas::MeResponse

        run_test! do
          body = JSON.parse(response.body)
          expect(body["user"]["email"]).to eq(api_key.user.email)
          expect(body["role"]).to eq("admin")
        end
      end
    end
  end
end
