# frozen_string_literal: true

module GiftShopItems
  class CreateService
    def initialize(project:, request:)
      @project = project
      @request = request
    end

    def call
      item = GiftShopItem.new(
        project: @project,
        name: @request.name,
        description: @request.description,
        points_cost: @request.points_cost,
        stock: @request.stock,
        enabled: @request.enabled
      )
      item.save
      item
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end
  end
end
