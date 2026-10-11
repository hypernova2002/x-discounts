require "rails_helper"
require "openapi_helper"

RSpec.describe "Campaigns API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/campaigns" do
    get "List campaigns" do
      tags "Campaigns"
      operationId "listCampaigns"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :q, in: :query, schema: { type: :string }, required: false

      response 200, "returns campaigns for the current project" do
        schema type: :object, properties: {
          campaigns: { type: :array, items: Schemas::Campaign },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:campaign, project: api_key.project) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["campaigns"]).not_to be_empty
        end
      end

      response 200, "filters by q, matching the name" do
        schema type: :object, properties: {
          campaigns: { type: :array, items: Schemas::Campaign },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          create(:campaign, project: api_key.project, name: "Spring Sale")
          create(:campaign, project: api_key.project, name: "Winter Clearance")
        end

        let(:q) { "spring" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["campaigns"].map { |c| c["name"] }).to eq(["Spring Sale"])
        end
      end

      response 200, "paginates with page and per_page" do
        schema type: :object, properties: {
          campaigns: { type: :array, items: Schemas::Campaign },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }
        parameter name: :page, in: :query, schema: { type: :integer }, required: false
        parameter name: :per_page, in: :query, schema: { type: :integer }, required: false

        before { 3.times { |i| create(:campaign, project: api_key.project, name: "Campaign #{i}") } }

        let(:per_page) { 2 }
        let(:page) { 2 }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["campaigns"].length).to eq(1)
          expect(body["meta"]).to eq("page" => 2, "pages" => 2, "count" => 3)
        end
      end
    end
  end
end
