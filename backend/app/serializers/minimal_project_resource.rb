# frozen_string_literal: true

# Used by /me. timezone/currency are included (despite the "minimal" name
# predating them) because the frontend's auth store is the only source of
# auth.project — every formatDate/formatDateTime/formatDateRange call site
# reads the project timezone from there, and every formatCurrency call site
# reads the project currency the same way, so omitting either here would
# silently make every one of them fall back to a hardcoded default instead
# of the project's configured setting, app-wide.
class MinimalProjectResource < ProjectResource
  def select(key, _value)
    %w[id name timezone currency].include?(key.to_s)
  end
end
