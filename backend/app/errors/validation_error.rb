# frozen_string_literal: true

class ValidationError < ApiError
  # Converts a Sequel model's errors into the {field, message} detail shape.
  # `prefix` namespaces the field names for nested records (e.g. "promotion.active_from").
  def self.details_for(model_errors, prefix: nil)
    model_errors.to_h.flat_map do |field, messages|
      field_name = field.is_a?(Array) ? field.join(",") : field.to_s
      field_name = "#{prefix}.#{field_name}" if prefix
      Array(messages).map { |message| { field: field_name, message: message } }
    end
  end

  def self.from_model(model, prefix: nil)
    new(details: details_for(model.errors, prefix: prefix))
  end

  def initialize(message: nil, details: [])
    super(:validation_failed, message: message, details: details)
  end
end
