require "rails_helper"
require "openapi_helper"

RSpec.describe "Activity Logs API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  # Auditable's db.after_commit hook never fires inside a spec's wrapping
  # (rolled-back) transaction, so rows are created directly here rather than by
  # performing a real audited action (see ActivityLogResource's spec).
  def log(**overrides)
    ActivityLog.create(
      {
        project_id: project.id, action: "create", entity_type: "Campaign", entity_id: 1,
        entity_public_id: "camp_1", entity_label: "Summer Sale", actor_label: "jane@example.com",
        changes: {}, request_id: "req-1", created_at: Time.now.utc
      }.merge(overrides)
    )
  end

  path "/api/v1/admin/activity_logs" do
    get "List activity logs" do
      tags "Activity Logs"
      operationId "listActivityLogs"
      produces "application/json"
      security [{ BearerAuth: [] }]
      parameter name: :entity_type, in: :query, schema: { type: :string }, required: false
      parameter name: :log_action, in: :query, schema: { type: :string }, required: false
      parameter name: :user_id, in: :query, schema: { type: :string }, required: false
      parameter name: :from, in: :query, schema: { type: :string }, required: false
      parameter name: :to, in: :query, schema: { type: :string }, required: false
      parameter name: :per_page, in: :query, schema: { type: :integer }, required: false

      response 200, "lists the project's logs, newest first" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          log(entity_label: "Older")
          log(entity_label: "Newer")
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].map { |l| l["entity_label"] }).to eq(%w[Newer Older])
        end
      end

      response 200, "never returns another project's logs" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          log
          other_project = create(:project)
          ActivityLog.create(project_id: other_project.id, action: "create", entity_type: "Campaign", entity_id: 2,
                              entity_label: "Other Project Campaign", changes: {}, created_at: Time.now.utc)
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].size).to eq(1)
        end
      end

      response 200, "filters by entity_type" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          log(entity_type: "Campaign", entity_label: "A Campaign")
          log(entity_type: "Discount", entity_label: "A Discount")
        end

        let(:entity_type) { "Discount" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].map { |l| l["entity_label"] }).to eq(["A Discount"])
        end
      end

      response 200, "filters by log_action" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          log(action: "create", entity_label: "Created")
          log(action: "update", entity_label: "Updated")
        end

        let(:log_action) { "update" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].map { |l| l["entity_label"] }).to eq(["Updated"])
        end
      end

      response 200, "filters by user_id (the user's public_id, same convention as every other id filter)" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        let(:acting_user) { create(:user, account: project.account) }

        before do
          log(user_id: acting_user.id, entity_label: "By acting user")
          log(entity_label: "By someone else")
        end

        let(:user_id) { acting_user.public_id }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].map { |l| l["entity_label"] }).to eq(["By acting user"])
        end
      end

      response 200, "returns no results for an unresolvable user_id, rather than erroring" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { log }

        let(:user_id) { "usr_nonexistent" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"]).to eq([])
        end
      end

      response 200, "never matches a user from a different account, even by raw id collision" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        let(:other_account_user) { create(:user) }

        before { log(user_id: other_account_user.id, entity_label: "Belongs to another account") }

        let(:user_id) { other_account_user.public_id }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"]).to eq([])
        end
      end

      response 200, "filters by a from/to date range" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          log(entity_label: "Too early", created_at: Date.new(2026, 1, 1))
          log(entity_label: "In range", created_at: Date.new(2026, 6, 15))
          log(entity_label: "Too late", created_at: Date.new(2026, 12, 1))
        end

        let(:from) { "2026-06-01" }
        let(:to) { "2026-06-30" }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].map { |l| l["entity_label"] }).to eq(["In range"])
        end
      end

      response 200, "paginates" do
        schema type: :object, properties: {
          activity_logs: { type: :array, items: Schemas::ActivityLog },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { 3.times { |i| log(entity_label: "Log #{i}") } }

        let(:per_page) { 2 }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["activity_logs"].size).to eq(2)
          expect(body["meta"]).to eq({ "page" => 1, "pages" => 2, "count" => 3 })
        end
      end
    end
  end
end
