# frozen_string_literal: true

class OrderLineItemResource
  include Alba::Resource

  attributes :sku, :quantity, :unit_price

  attribute(:metadata) { |line_item| line_item.metadata.to_h }
end
