require "rails_helper"
require "openapi_helper"

RSpec.describe "Project Memberships API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/project_memberships" do
    get "List project memberships" do
      tags "Project Memberships"
      operationId "listProjectMemberships"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns memberships for the current project" do
        schema type: :object, properties: {
          project_memberships: { type: :array, items: Schemas::ProjectMembership },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["project_memberships"]).not_to be_empty
        end
      end
    end

    post "Add a member to the current project" do
      tags "Project Memberships"
      operationId "createProjectMembership"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::ProjectMembershipCreateRequest }
      }

      response 201, "membership created" do
        schema Schemas::ProjectMembership
        let(:new_user) { create(:user, account: api_key.user.account) }
        let(:request_body) { { user_id: new_user.public_id, role: "viewer" } }

        run_test!
      end

      response 403, "not a project admin" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:new_user) { create(:user, account: api_key.user.account) }
        let(:request_body) { { user_id: new_user.public_id, role: "viewer" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/project_memberships/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    let(:member) { create(:project_membership, project: api_key.project, role: "viewer") }

    get "Show a project membership" do
      tags "Project Memberships"
      operationId "getProjectMembership"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the membership" do
        schema Schemas::ProjectMembership
        let(:id) { member.public_id }

        run_test!
      end
    end

    patch "Update a project membership" do
      tags "Project Memberships"
      operationId "updateProjectMembership"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: { type: :object, properties: { role: { type: :string } } } }
      }

      response 200, "role updated" do
        schema Schemas::ProjectMembership
        let(:id) { member.public_id }
        let(:request_body) { { role: "developer" } }

        run_test!
      end
    end

    delete "Remove a project membership" do
      tags "Project Memberships"
      operationId "deleteProjectMembership"
      security [{ BearerAuth: [] }]

      response 204, "membership removed" do
        let(:id) { member.public_id }

        run_test!
      end

      response 422, "cannot remove the last admin" do
        schema Schemas::Error
        let(:id) { api_key.user.project_memberships_dataset.first(project_id: api_key.project.id).public_id }

        run_test!
      end
    end
  end
end
