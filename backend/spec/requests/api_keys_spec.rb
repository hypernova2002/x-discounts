require "rails_helper"
require "openapi_helper"

RSpec.describe "API Keys API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/api_keys" do
    get "List API keys" do
      tags "API Keys"
      operationId "listApiKeys"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns keys for the current project (no token field)" do
        schema type: :object, properties: {
          api_keys: { type: :array, items: Schemas::ApiKey },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["api_keys"]).not_to be_empty
          expect(body["api_keys"].first).not_to have_key("token")
        end
      end
    end

    post "Create an API key" do
      tags "API Keys"
      operationId "createApiKey"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::ApiKeyCreateRequest }
      }

      response 201, "key created (raw token included once)" do
        schema Schemas::ApiKeyWithToken
        let(:new_user) { create(:user, account: api_key.user.account) }
        let(:request_body) { { user_id: new_user.public_id, role: "viewer", name: "CI key" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["token"]).to start_with("xdk_")
        end
      end

      response 422, "invalid user_id" do
        schema Schemas::Error
        let(:request_body) { { user_id: "usr_nonexistent", role: "viewer", name: "CI key" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/api_keys/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show an API key" do
      tags "API Keys"
      operationId "getApiKey"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the key" do
        schema Schemas::ApiKey
        let(:id) { api_key.public_id }

        run_test!
      end
    end

    delete "Revoke an API key" do
      tags "API Keys"
      operationId "revokeApiKey"
      security [{ BearerAuth: [] }]

      response 204, "key revoked" do
        let(:id) do
          other_user = create(:user, account: api_key.user.account)
          create(:api_key, project: api_key.project, user: other_user, role: "viewer").public_id
        end

        run_test!
      end
    end
  end
end
