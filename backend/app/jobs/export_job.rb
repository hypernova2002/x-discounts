# frozen_string_literal: true

# Enqueued by ExportsController#create. Deliberately doesn't retry on failure —
# Exports::GenerateService already rescues internally and marks the row
# "failed" with the error, and a CSV-generation failure is deterministic
# (bad data/filter), so Sidekiq retrying would just fail the same way again
# while leaving the row stuck on "processing" in between attempts.
class ExportJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    export = Export[export_id]
    return unless export

    export.update(status: "processing")
    Exports::GenerateService.new(export: export).call
  end
end
