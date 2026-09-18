# frozen_string_literal: true

module Api
  module V1
    class SignupsController < ApplicationController
      skip_before_action :authenticate!, only: :create

      def create
        result = Signups::CreateService.new(request: SignupRequest.new(body)).call
        render json: {
          token: result[:session].raw_token,
          user: MinimalUserResource.new(result[:user]).to_h
        }, status: :created
      end
    end
  end
end
