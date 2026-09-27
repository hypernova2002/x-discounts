# frozen_string_literal: true

# Generic activity-log capture for any model that includes it. Each hook
# captures a stable snapshot into local variables, then defers the actual
# write to db.after_commit — so a change that's part of a transaction that
# ultimately rolls back never produces a log row. Field-level diffs (update)
# come from Sequel's own dirty-tracking plugin; create/delete log the full
# row, since there's no other side to diff against.
module Auditable
  SENSITIVE_COLUMNS = %i[password_digest token_digest otp_secret otp_backup_codes].freeze

  def self.included(base)
    base.plugin :dirty
  end

  def after_create
    super
    log_activity("create", redacted(values))
  end

  def after_update
    super
    changes = redacted(column_changes).except(:created_at, :updated_at)
    log_activity("update", changes) if changes.any?
  end

  def after_destroy
    super
    log_activity("delete", redacted(values))
  end

  # Overridden per-model only where the project can't be read off a direct column.
  def audit_project_id
    respond_to?(:project_id) ? project_id : (is_a?(Project) ? id : nil)
  end

  # Overridden per-model only where none of these common attributes is the right label.
  def audit_label
    %i[name code external_id key].each { |a| return send(a) if respond_to?(a) && send(a).present? }
    respond_to?(:public_id) ? public_id : "#{model.name} ##{id}"
  end

  private

  def log_activity(action, changes)
    project_id = audit_project_id
    return unless project_id # nothing sensible to scope this to — skip rather than guess

    attrs = {
      project_id: project_id,
      user_id: Current.user&.id,
      actor_label: Current.user&.email,
      action: action,
      entity_type: self.class.name,
      entity_id: id,
      entity_public_id: (respond_to?(:public_id) ? public_id : nil),
      entity_label: audit_label,
      changes: changes,
      request_id: Current.request_id
    }
    # Best-effort: if the owning project (or another FK target) was itself
    # deleted in the same transaction — e.g. destroying a project cascades to
    # destroy its campaigns, and each campaign's own after_commit then tries to
    # log a "delete" referencing a project_id that's already gone by the time
    # this fires — logging must never break the real operation it's describing.
    db.after_commit do
      begin
        ActivityLog.create(attrs)
      rescue Sequel::ForeignKeyConstraintViolation => e
        Rails.logger.warn("ActivityLog skipped (FK target gone): #{e.message}")
      end
    end
  end

  def redacted(hash)
    hash.reject { |k, v| SENSITIVE_COLUMNS.include?(k.to_sym) || internal_id_column?(k, v) }
  end

  # Strips the row's own `id` and any `*_id` foreign key — meaningless/leaky
  # outside the database, unlike a text business identifier that happens to
  # share the naming convention (external_id, public_id) which this keeps,
  # since those are never Integers. `v` is a scalar for a create/delete
  # snapshot, or an [old, new] pair for an update diff — checks whichever
  # value would actually indicate a surrogate key (the newest one).
  def internal_id_column?(key, v)
    return false unless key.to_s == "id" || key.to_s.end_with?("_id")

    sample = v.is_a?(Array) ? v.last : v
    !sample.is_a?(String)
  end
end
