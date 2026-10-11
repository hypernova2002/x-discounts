require "rails_helper"
require "openapi_helper"

RSpec.describe "Membership Schemes API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/membership_schemes" do
    get "List membership schemes" do
      tags "Membership Schemes"
      operationId "listMembershipSchemes"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :q, in: :query, schema: { type: :string }, required: false

      response 200, "returns membership schemes for the current project" do
        schema type: :object, properties: {
          membership_schemes: { type: :array, items: Schemas::MembershipScheme },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:membership_scheme, project: api_key.project) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["membership_schemes"]).not_to be_empty
        end
      end

      response 200, "filters by q, matching the name" do
        schema type: :object, properties: {
          membership_schemes: { type: :array, items: Schemas::MembershipScheme },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          create(:membership_scheme, project: api_key.project, name: "Gold Tier Program")
          create(:membership_scheme, project: api_key.project, name: "Standard")
        end

        let(:q) { "gold" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["membership_schemes"].map { |s| s["name"] }).to eq(["Gold Tier Program"])
        end
      end
    end
  end
end
