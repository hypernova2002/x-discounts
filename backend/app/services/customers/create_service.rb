# frozen_string_literal: true

module Customers
  # Find-or-create by external_id, updating any newly-submitted fields onto an
  # existing record. Takes a plain hash (not a typed request struct) so it can be
  # reused from both the dedicated customer endpoint and the redeem flow's inline
  # customer data — the latter is only loosely typed, since it also carries arbitrary
  # custom-attribute keys the service has no business validating.
  class CreateService
    ATTRS = %i[name email phone_number country date_of_birth marketing_opt_in].freeze

    def initialize(project:, attrs:)
      @project = project
      @attrs = attrs.to_h.with_indifferent_access
    end

    def call
      external_id = @attrs[:external_id]
      raise ValidationError.new(details: [{ field: "external_id", message: "is required" }]) if external_id.blank?

      customer = Customer.first(project_id: @project.id, external_id: external_id)
      customer ||= Customer.new(project: @project, external_id: external_id)
      customer.set(known_attrs)
      customer.metadata = customer.metadata.to_h.merge(custom_attrs) if custom_attrs.any?
      customer.save
      customer
    rescue Sequel::ValidationFailed => e
      raise ValidationError.from_model(e.model)
    end

    private

    def known_attrs
      ATTRS.each_with_object({}) { |key, memo| memo[key] = @attrs[key] if @attrs.key?(key) }
    end

    # Anything beyond external_id and the known columns is a custom attribute — covers
    # both an explicit `metadata` hash (the dedicated customer endpoint) and flat
    # custom-attribute keys sent inline (the redeem flow's loosely-typed customer hash).
    def custom_attrs
      @attrs[:metadata].presence.to_h.merge(@attrs.except(:external_id, :metadata, *ATTRS))
    end
  end
end
