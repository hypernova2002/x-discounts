# frozen_string_literal: true

Sequel.database_timezone = :utc
Sequel.application_timezone = :utc

# No connection exists yet when running db:create against a brand-new database
# (e.g. a fresh test database) — skip rather than error in that case.
begin
  Sequel::Model.db.extension :pg_json
rescue Sequel::Error
  nil
end
