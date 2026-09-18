require "rails_helper"
require "openapi_helper"

RSpec.describe "Users API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/users" do
    get "List users" do
      tags "Users"
      operationId "listUsers"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns users for the current account" do
        schema type: :object, properties: {
          users: { type: :array, items: Schemas::User },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["users"]).not_to be_empty
        end
      end
    end

    post "Create a user" do
      tags "Users"
      operationId "createUser"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::UserCreateRequest }
      }

      response 201, "user created" do
        schema Schemas::User
        let(:request_body) { { name: "New User", email: "new-#{SecureRandom.hex(4)}@example.com" } }

        run_test!
      end

      response 422, "validation error" do
        schema Schemas::Error
        let(:request_body) { { name: "" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/users/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show a user" do
      tags "Users"
      operationId "getUser"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the user" do
        schema Schemas::User
        let(:id) { api_key.user.public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "usr_nonexistent" }

        run_test!
      end
    end

    patch "Update a user" do
      tags "Users"
      operationId "updateUser"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: { type: :object, properties: { name: { type: :string }, email: { type: :string } } } }
      }

      response 200, "user updated" do
        schema Schemas::User
        let(:id) { api_key.user.public_id }
        let(:request_body) { { name: "Renamed" } }

        run_test!
      end
    end

    delete "Delete a user" do
      tags "Users"
      operationId "deleteUser"
      security [{ BearerAuth: [] }]

      response 204, "user deleted" do
        let(:id) { create(:user, account: api_key.user.account).public_id }

        run_test!
      end
    end
  end
end
