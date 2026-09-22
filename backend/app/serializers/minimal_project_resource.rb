# frozen_string_literal: true

# Used by /me. timezone is included (despite the "minimal" name predating it)
# because the frontend's auth store is the only source of auth.project — every
# formatDate/formatDateTime/formatDateRange call site reads the project
# timezone from there, so omitting it here silently made every one of them
# fall back to the browser's local zone instead of the project's configured
# one, app-wide.
class MinimalProjectResource < ProjectResource
  def select(key, _value)
    %w[id name timezone].include?(key.to_s)
  end
end
