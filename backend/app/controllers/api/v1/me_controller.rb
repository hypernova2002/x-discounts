# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: {
          project: current_project ? MinimalProjectResource.new(current_project).to_h : nil,
          user: MinimalUserResource.new(current_user).to_h,
          role: current_role
        }
      end
    end
  end
end
