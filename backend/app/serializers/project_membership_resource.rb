# frozen_string_literal: true

class ProjectMembershipResource
  include Alba::Resource

  attribute :id, &:public_id
  attribute(:project_id) { |membership| membership.project.public_id }
  attribute(:user_id) { |membership| membership.user.public_id }
  attributes :role, :created_at, :updated_at
end
