# frozen_string_literal: true

module GiftShopItems
  class UpdateService
    def initialize(item:, request:)
      @item = item
      @request = request
    end

    def call
      @item.name = @request.name if @request.attributes.key?(:name)
      @item.description = @request.description if @request.attributes.key?(:description)
      @item.points_cost = @request.points_cost if @request.attributes.key?(:points_cost)
      @item.stock = @request.stock if @request.attributes.key?(:stock)
      @item.enabled = @request.enabled if @request.attributes.key?(:enabled)
      @item.save
      @item
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
