# frozen_string_literal: true

# Deliberately does NOT include Auditable — that would recurse (logging the
# creation of a log entry). All the write logic lives in Auditable itself;
# this class is just the table.
class ActivityLog < Sequel::Model
  PUBLIC_ID_PREFIX = "alog"

  include PublicIdentifiable

  many_to_one :project
  many_to_one :user
end
