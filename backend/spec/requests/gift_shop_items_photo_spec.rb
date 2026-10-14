require "rails_helper"
require "rack/test"
require "tempfile"

# Multipart file upload/download doesn't fit the JSON-oriented openapi DSL used
# elsewhere in spec/requests — plain request-spec coverage instead, same as the
# rest of this controller's actions (spec/requests/gift_shop_items_spec.rb).
RSpec.describe "Gift Shop Items Photo API", type: :request do
  let(:api_key) { create(:api_key, role: "admin") }
  let(:headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }
  let(:project) { api_key.project }
  let(:item) { create(:gift_shop_item, project: project) }

  def uploaded_png
    file = Tempfile.new(["photo", ".png"])
    file.binmode
    file.write("fake png bytes")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  after do
    Dir.glob(GiftShopItems::AttachPhotoService.storage_dir.join("#{item.public_id}.*")).each { |path| File.delete(path) }
  end

  describe "POST /api/v1/admin/gift_shop_items/:id/photo" do
    it "attaches the uploaded photo" do
      post "/api/v1/admin/gift_shop_items/#{item.public_id}/photo", params: { photo: uploaded_png }, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["photo_url"]).to eq("/api/v1/admin/gift_shop_items/#{item.public_id}/photo")
      expect(item.reload.photo_content_type).to eq("image/png")
    end

    it "raises on field photo when no file is given" do
      post "/api/v1/admin/gift_shop_items/#{item.public_id}/photo", params: {}, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["error"]["details"]).to include(hash_including("field" => "photo"))
    end
  end

  describe "GET /api/v1/admin/gift_shop_items/:id/photo" do
    it "serves the photo without requiring authentication" do
      post "/api/v1/admin/gift_shop_items/#{item.public_id}/photo", params: { photo: uploaded_png }, headers: headers

      get "/api/v1/admin/gift_shop_items/#{item.public_id}/photo"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("image/png")
      expect(response.body).to eq("fake png bytes")
    end

    it "returns 404 for an item with no photo" do
      get "/api/v1/admin/gift_shop_items/#{item.public_id}/photo"
      expect(response).to have_http_status(:not_found)
    end
  end
end
