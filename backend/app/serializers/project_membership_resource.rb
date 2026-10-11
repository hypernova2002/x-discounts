# frozen_string_literal: true

class ProjectMembershipResource < ApplicationResource
  attribute :id, &:public_id
  attribute(:project_id, if: proc { included?(:project_id) }) { |membership| membership.project.public_id }
  attribute(:user_id, if: proc { included?(:user_id) }) { |membership| membership.user.public_id }
  attributes :role, :created_at, :updated_at
end
