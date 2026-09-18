# frozen_string_literal: true

# Used for signup/login responses, which only ever returned {id, name, email} —
# no timestamps. Inherits UserResource's full attribute list and filters it down
# rather than redeclaring the shared fields.
class MinimalUserResource < UserResource
  def select(key, _value)
    %w[id name email locale].include?(key.to_s)
  end
end
