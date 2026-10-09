# frozen_string_literal: true

# A record of one background export run (see Exports::GenerateService and
# ExportJob) — system-generated, so (like ActivityLog) this deliberately does
# NOT include Auditable.
class Export < Sequel::Model
  PUBLIC_ID_PREFIX = "exp"

  TYPES = %w[campaigns customers orders project].freeze
  STATUSES = %w[pending processing completed failed].freeze

  include PublicIdentifiable

  plugin :validation_helpers

  many_to_one :project
  many_to_one :user

  def validate
    super
    validates_presence %i[project_id export_type status]
    validates_includes TYPES, :export_type, allow_missing: true
    validates_includes STATUSES, :status, allow_missing: true
  end

  def completed?
    status == "completed"
  end

  def file_path
    return nil unless filename

    Rails.root.join("storage", "exports", "#{public_id}#{File.extname(filename)}")
  end
end
