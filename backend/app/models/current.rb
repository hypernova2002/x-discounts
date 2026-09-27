# frozen_string_literal: true

# Request-scoped actor/grouping context for activity logging (see
# app/models/concerns/auditable.rb) — set once per request in
# ApplicationController, read by any model save anywhere in that request
# without threading it through every service call site individually.
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id
end
