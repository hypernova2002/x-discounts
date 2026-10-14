# frozen_string_literal: true

class MinimalAccountResource < AccountResource
  def select(key, _value)
    %w[id name].include?(key.to_s)
  end
end
