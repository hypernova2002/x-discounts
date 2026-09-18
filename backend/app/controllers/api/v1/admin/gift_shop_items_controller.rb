# frozen_string_literal: true

module Api
  module V1
    module Admin
      class GiftShopItemsController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        # photo is served to a bare <img src>, which can't attach an Authorization
        # header — it's public, relying on the item's opaque public_id as the only
        # access control (the same trust model as a signed/unlisted URL).
        skip_before_action :authenticate!, only: %i[photo]
        before_action :require_project_context!, except: %i[photo]
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create update destroy upload_photo]
        before_action :set_item, only: %i[show update destroy upload_photo redeem]
        before_action :set_item_by_public_id, only: %i[photo]

        def index
          dataset = current_project.gift_shop_items_dataset.order(Sequel.desc(:id))
          pagy, items = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { gift_shop_items: GiftShopItemResource.new(items).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: GiftShopItemResource.new(@item).to_h
        end

        def create
          item = GiftShopItems::CreateService.new(project: current_project, request: GiftShopItemRequest.new(body)).call
          render json: GiftShopItemResource.new(item).to_h, status: :created
        end

        def update
          item = GiftShopItems::UpdateService.new(item: @item, request: GiftShopItemUpdateRequest.new(body)).call
          render json: GiftShopItemResource.new(item).to_h
        end

        def destroy
          @item.destroy
          head :no_content
        end

        def upload_photo
          file = params[:photo]
          raise ValidationError.new(details: [{ field: "photo", message: "is required" }]) unless file.respond_to?(:read)

          item = GiftShopItems::AttachPhotoService.new(item: @item, file: file).call
          render json: GiftShopItemResource.new(item).to_h
        end

        def photo
          raise ApiError.new(:not_found) unless @item&.photo?

          send_file @item.photo_path.to_s, type: @item.photo_content_type, disposition: "inline"
        end

        def redeem
          request = GiftShopRedeemRequest.new(body)
          redemption = GiftShop::RedeemItemService.new(
            project: current_project,
            item: @item,
            customer_external_id: request.customer_external_id,
            quantity: request.quantity
          ).call
          render json: GiftShopRedemptionResource.new(redemption).to_h, status: :created
        end

        private

        def set_item
          @item = current_project.gift_shop_items_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @item
        end

        def set_item_by_public_id
          @item = GiftShopItem.first(public_id: params[:id])
        end
      end
    end
  end
end
