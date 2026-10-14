require "rails_helper"
require "openapi_helper"

RSpec.describe "Points Redemptions API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:order) { create(:order, project: project) }

  path "/api/v1/admin/points_redemptions/{id}/refund" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    post "Refund a points redemption" do
      tags "Points Redemptions"
      operationId "refundPointsRedemption"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "refunds the full remaining points" do
        schema Schemas::RefundResult
        let(:id) { create(:points_redemption, order: order, customer: order.customer, points_redeemed: 50).public_id }
        let(:request_body) { {} }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["points"]).to eq(50)
        end
      end

      response 404, "an id belonging to another project" do
        schema Schemas::Error
        let(:other_order) { create(:order) }
        let(:id) { create(:points_redemption, order: other_order, customer: other_order.customer, points_redeemed: 50).public_id }
        let(:request_body) { {} }

        run_test!
      end

      response 422, "nothing left to refund" do
        schema Schemas::Error
        let(:id) do
          points_redemption = create(:points_redemption, order: order, customer: order.customer, points_redeemed: 50)
          Refunds::CreateService.new(points_redemption: points_redemption).call
          points_redemption.public_id
        end
        let(:request_body) { {} }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["error"]["details"]).to include(hash_including("field" => "points"))
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:id) { create(:points_redemption, order: order, customer: order.customer, points_redeemed: 50).public_id }
        let(:request_body) { {} }

        run_test!
      end
    end
  end
end
