# frozen_string_literal: true

class ActivityLogResource
  include Alba::Resource

  attribute :id, &:public_id
  attributes :action, :entity_type, :entity_label, :entity_public_id, :actor_label, :changes, :request_id, :created_at
end
