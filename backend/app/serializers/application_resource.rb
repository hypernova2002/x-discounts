# frozen_string_literal: true

class ApplicationResource
  include Alba::Resource

  # Shared by every resource's gated attribute/association `if:` blocks — see
  # Includable in the controllers for how `includes` gets populated.
  def included?(name)
    Array(params[:includes]).include?(name.to_s)
  end
end
