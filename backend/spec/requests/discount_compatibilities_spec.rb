require "rails_helper"
require "openapi_helper"

RSpec.describe "Discount Compatibilities API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) { create(:discount, project: project, campaign: campaign, stackable: false) }
  let(:discount_id) { discount.public_id }

  path "/api/v1/admin/discounts/{discount_id}/compatible_discounts" do
    parameter name: :discount_id, in: :path, schema: { type: :string }, required: true

    post "Mark another discount as compatible" do
      tags "Discount Compatibilities"
      operationId "createDiscountCompatibility"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "returns the discount, now compatible with the other" do
        schema Schemas::Discount
        let(:other) { create(:discount, project: project, campaign: campaign, stackable: false) }
        let(:request_body) { { compatible_discount_id: other.public_id } }

        run_test! do
          expect(discount.reload.compatible_discounts.map(&:public_id)).to include(other.public_id)
        end
      end

      response 422, "an unresolvable compatible_discount_id" do
        schema Schemas::Error
        let(:request_body) { { compatible_discount_id: "disc_nonexistent" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]["details"]).to include(hash_including("field" => "compatible_discount_id"))
        end
      end

      response 422, "pairing a discount with itself" do
        schema Schemas::Error
        let(:request_body) { { compatible_discount_id: discount.public_id } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]["details"]).to include(hash_including("field" => "compatible_discount_id"))
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:other) { create(:discount, project: project, campaign: campaign) }
        let(:request_body) { { compatible_discount_id: other.public_id } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/discounts/{discount_id}/compatible_discounts/{id}" do
    parameter name: :discount_id, in: :path, schema: { type: :string }, required: true
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    delete "Remove a compatibility" do
      tags "Discount Compatibilities"
      operationId "deleteDiscountCompatibility"
      security [{ BearerAuth: [] }]

      response 204, "removes an existing compatibility" do
        let(:other) { create(:discount, project: project, campaign: campaign) }
        let(:id) { other.public_id }

        before { DiscountStackingCompatibilities::CreateService.new(discount: discount, compatible_discount: other).call }

        run_test!
      end

      response 204, "is a no-op when no compatibility row exists" do
        let(:id) { create(:discount, project: project, campaign: campaign).public_id }
        run_test!
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:id) { create(:discount, project: project, campaign: campaign).public_id }
        run_test!
      end
    end
  end
end
