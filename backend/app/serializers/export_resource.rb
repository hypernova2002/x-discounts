# frozen_string_literal: true

class ExportResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :export_type, :status, :filename, :byte_size, :error_message, :created_at, :completed_at

  attribute(:requested_by) { |export| export.user&.name || export.user&.email }
end
