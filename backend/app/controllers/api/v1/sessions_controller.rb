# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate!, only: :create

      def create
        request = LoginRequest.new(body)

        user = User.first(email: request.email)
        raise ApiError.new(:invalid_credentials) unless user&.authenticate(request.password)

        session = Session.create_for(user: user)
        render json: { token: session.raw_token, user: MinimalUserResource.new(user).to_h }, status: :created
      end

      def destroy
        current_session&.destroy
        head :no_content
      end
    end
  end
end
