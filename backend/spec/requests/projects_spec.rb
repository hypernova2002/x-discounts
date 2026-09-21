require "rails_helper"
require "openapi_helper"

RSpec.describe "Projects API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/projects" do
    get "List projects" do
      tags "Projects"
      operationId "listProjects"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns projects visible to the current user" do
        schema type: :object, properties: {
          projects: { type: :array, items: Schemas::Project },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["projects"]).not_to be_empty
        end
      end
    end

    post "Create a project" do
      tags "Projects"
      operationId "createProject"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::ProjectCreateRequest }
      }

      response 201, "project created" do
        schema Schemas::Project
        let(:request_body) { { name: "New Project" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["timezone"]).to eq("UTC")
        end
      end

      response 201, "project created with an explicit timezone" do
        schema Schemas::Project
        let(:request_body) { { name: "New Project", timezone: "Asia/Tokyo" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["timezone"]).to eq("Asia/Tokyo")
        end
      end

      response 403, "not an account admin" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { name: "New Project" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/projects/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show a project" do
      tags "Projects"
      operationId "getProject"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the project" do
        schema Schemas::Project
        let(:id) { api_key.project.public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "proj_nonexistent" }

        run_test!
      end
    end

    patch "Update a project" do
      tags "Projects"
      operationId "updateProject"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: { type: :object, properties: { name: { type: :string }, timezone: { type: :string } } } }
      }

      response 200, "project updated" do
        schema Schemas::Project
        let(:id) { api_key.project.public_id }
        let(:request_body) { { name: "Renamed" } }

        run_test!
      end

      response 200, "project timezone updated" do
        schema Schemas::Project
        let(:id) { api_key.project.public_id }
        let(:request_body) { { timezone: "Asia/Tokyo" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["timezone"]).to eq("Asia/Tokyo")
        end
      end

      response 422, "invalid timezone" do
        schema Schemas::Error
        let(:id) { api_key.project.public_id }
        let(:request_body) { { timezone: "Not/AZone" } }

        run_test!
      end
    end

    delete "Delete a project" do
      tags "Projects"
      operationId "deleteProject"
      security [{ BearerAuth: [] }]

      response 204, "project deleted" do
        let(:id) do
          other = create(:project, account: api_key.user.account)
          create(:project_membership, project: other, user: api_key.user, role: "admin")
          other.public_id
        end

        run_test!
      end
    end
  end
end
