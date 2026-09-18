require "rails_helper"
require "openapi_helper"

RSpec.describe "Sessions API", type: :openapi do
  let(:password) { "supersecret123" }
  let(:user) do
    u = create(:user)
    u.password = password
    u.password_confirmation = password
    u.save
    u
  end

  path "/api/v1/login" do
    post "Sign in" do
      tags "Sessions"
      operationId "login"
      consumes "application/json"
      produces "application/json"

      request_body required: true, content: {
        "application/json" => { schema: Schemas::LoginRequest }
      }

      response 201, "signed in" do
        schema Schemas::SessionResponse
        let(:request_body) { { email: user.email, password: password } }

        run_test!
      end

      response 401, "invalid credentials" do
        schema Schemas::Error
        let(:request_body) { { email: user.email, password: "wrong" } }

        run_test!
      end
    end
  end

  path "/api/v1/logout" do
    delete "Sign out" do
      tags "Sessions"
      operationId "logout"
      security [{ BearerAuth: [] }]

      let(:request_headers) do
        session = Session.create_for(user: user)
        { "Authorization" => "Bearer #{session.raw_token}" }
      end

      response 204, "signed out" do
        run_test!
      end
    end
  end
end
