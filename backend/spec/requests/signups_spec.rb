require "rails_helper"
require "openapi_helper"

RSpec.describe "Signups API", type: :openapi do
  path "/api/v1/signup" do
    post "Create an account" do
      tags "Signups"
      operationId "createSignup"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: {
        "application/json" => { schema: Schemas::SignupRequest }
      }

      response 201, "account created, signed in" do
        schema Schemas::SessionResponse
        let(:request_body) do
          {
            account_name: "New Co",
            name: "Nina Founder",
            email: "nina-#{SecureRandom.hex(4)}@example.com",
            password: "supersecret123",
            password_confirmation: "supersecret123"
          }
        end

        run_test!
      end

      response 422, "validation error" do
        schema Schemas::Error
        let(:request_body) { { account_name: "New Co" } }

        run_test!
      end
    end
  end
end
