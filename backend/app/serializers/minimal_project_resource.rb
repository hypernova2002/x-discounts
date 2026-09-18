# frozen_string_literal: true

# Used by /me, which only ever returned {id, name} for the current project.
class MinimalProjectResource < ProjectResource
  def select(key, _value)
    %w[id name].include?(key.to_s)
  end
end
