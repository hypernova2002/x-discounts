require "rails_helper"
require "openapi_helper"

RSpec.describe "Exports API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  path "/api/v1/admin/exports" do
    get "List exports" do
      tags "Exports"
      operationId "listExports"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns exports for the current project, most recent first" do
        schema type: :object, properties: {
          exports: { type: :array, items: Schemas::Export },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before do
          create(:export, project: api_key.project, export_type: "campaigns")
          create(:export, project: api_key.project, export_type: "orders")
        end

        run_test! do
          body = JSON.parse(response.body)
          expect(body["exports"].map { |e| e["export_type"] }).to contain_exactly("campaigns", "orders")
        end
      end

      response 200, "does not include another project's exports" do
        schema type: :object, properties: {
          exports: { type: :array, items: Schemas::Export },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:export) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["exports"]).to be_empty
        end
      end
    end

    post "Create an export" do
      tags "Exports"
      operationId "createExport"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]

      request_body required: true, content: {
        "application/json" => { schema: Schemas::ExportCreateRequest }
      }

      response 201, "export queued" do
        schema Schemas::Export
        let(:request_body) { { export_type: "campaigns", params: { include_archived: true } } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["status"]).to eq("pending")
          export = Export.first(public_id: body["id"])
          expect(export.params).to eq("include_archived" => true)
          expect(export.user_id).to eq(api_key.user_id)
        end
      end

      response 422, "invalid export_type" do
        schema Schemas::Error
        let(:request_body) { { export_type: "bogus" } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/exports/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show an export" do
      tags "Exports"
      operationId "getExport"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the export" do
        schema Schemas::Export
        let(:id) { create(:export, project: api_key.project, status: "completed", filename: "campaigns.csv").public_id }

        run_test!
      end

      response 404, "not found" do
        schema Schemas::Error
        let(:id) { "exp_nonexistent" }

        run_test!
      end
    end
  end

  path "/api/v1/admin/exports/{id}/download" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Download a completed export" do
      tags "Exports"
      operationId "downloadExport"
      security [{ BearerAuth: [] }]

      response 200, "streams the generated file" do
        let(:export) do
          export = create(:export, project: api_key.project, status: "completed", filename: "campaigns.csv", content_type: "text/csv")
          FileUtils.mkdir_p(File.dirname(export.file_path))
          File.write(export.file_path, "name\nTest\n")
          export
        end
        let(:id) { export.public_id }

        after { File.delete(export.file_path) if File.exist?(export.file_path) }

        run_test! do
          expect(response.body).to eq("name\nTest\n")
          expect(response.headers["Content-Type"]).to eq("text/csv")
        end
      end

      response 404, "not yet completed" do
        schema Schemas::Error
        let(:id) { create(:export, project: api_key.project, status: "processing").public_id }

        run_test!
      end
    end
  end
end
