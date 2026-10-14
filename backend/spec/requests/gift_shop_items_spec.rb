require "rails_helper"
require "openapi_helper"

RSpec.describe "Gift Shop Items API", type: :openapi do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:request_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }

  path "/api/v1/admin/gift_shop_items" do
    get "List gift shop items" do
      tags "Gift Shop Items"
      operationId "listGiftShopItems"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "lists the project's items" do
        schema type: :object, properties: {
          gift_shop_items: { type: :array, items: Schemas::GiftShopItem },
          meta: { type: :object, properties: { page: { type: :integer }, pages: { type: :integer }, count: { type: :integer } } }
        }

        before { create(:gift_shop_item, project: project, name: "Mug") }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["gift_shop_items"].map { |i| i["name"] }).to eq(["Mug"])
        end
      end
    end

    post "Create a gift shop item" do
      tags "Gift Shop Items"
      operationId "createGiftShopItem"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "creates an item" do
        schema Schemas::GiftShopItem
        let(:request_body) { { name: "Mug", points_cost: 100 } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("Mug")
        end
      end

      response 403, "not a write role" do
        schema Schemas::Error
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { name: "Mug", points_cost: 100 } }

        run_test!
      end
    end
  end

  path "/api/v1/admin/gift_shop_items/{id}" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    get "Show a gift shop item" do
      tags "Gift Shop Items"
      operationId "getGiftShopItem"
      produces "application/json"
      security [{ BearerAuth: [] }]

      response 200, "returns the item" do
        schema Schemas::GiftShopItem
        let(:id) { create(:gift_shop_item, project: project, name: "Mug").public_id }
        run_test!
      end

      response 404, "unknown item" do
        schema Schemas::Error
        let(:id) { "gift_nonexistent" }
        run_test!
      end
    end

    patch "Update a gift shop item" do
      tags "Gift Shop Items"
      operationId "updateGiftShopItem"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 200, "updates the item" do
        schema Schemas::GiftShopItem
        let(:id) { create(:gift_shop_item, project: project, name: "Old Name").public_id }
        let(:request_body) { { name: "New Name" } }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["name"]).to eq("New Name")
        end
      end
    end

    delete "Delete a gift shop item" do
      tags "Gift Shop Items"
      operationId "deleteGiftShopItem"
      security [{ BearerAuth: [] }]

      response 204, "deletes the item" do
        let(:id) { create(:gift_shop_item, project: project).public_id }
        run_test!
      end
    end
  end

  path "/api/v1/admin/gift_shop_items/{id}/redeem" do
    parameter name: :id, in: :path, schema: { type: :string }, required: true

    post "Redeem a gift shop item for a customer" do
      tags "Gift Shop Items"
      operationId "redeemGiftShopItem"
      consumes "application/json"
      produces "application/json"
      security [{ BearerAuth: [] }]
      request_body required: true, content: { "application/json" => { schema: { type: :object } } }

      response 201, "redeems the item, requiring no write role" do
        schema Schemas::GiftShopRedemption
        let(:item) { create(:gift_shop_item, project: project, name: "Mug", points_cost: 50) }
        let(:customer) { create(:customer, project: project, external_id: "cust-1") }
        let(:id) { item.public_id }
        let(:api_key) { create(:api_key, role: "viewer") }
        let(:request_body) { { customer_external_id: "cust-1" } }

        before { create(:loyalty_point_lot, customer: customer, points: 100) }

        run_test! do
          body = JSON.parse(response.body)
          expect(body["item_name"]).to eq("Mug")
        end
      end

      response 422, "insufficient points" do
        schema Schemas::Error
        let(:item) { create(:gift_shop_item, project: project, points_cost: 500) }
        let(:customer) { create(:customer, project: project, external_id: "cust-1") }
        let(:id) { item.public_id }
        let(:request_body) { { customer_external_id: "cust-1" } }

        before { create(:loyalty_point_lot, customer: customer, points: 10) }

        run_test!
      end
    end
  end
end
