# frozen_string_literal: true

module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate!, only: %i[create verify_otp]

      def create
        request = LoginRequest.new(body)

        user = User.first(email: request.email)
        raise ApiError.new(:invalid_credentials) unless user&.authenticate(request.password)

        if user.otp_enabled
          challenge = OtpChallenge.create_for(user: user)
          render json: { otp_required: true, otp_challenge_token: challenge.raw_token }, status: :ok
          return
        end

        session = Session.create_for(user: user)
        render json: { token: session.raw_token, user: MinimalUserResource.new(user).to_h }, status: :created
      end

      def verify_otp
        request = OtpVerifyRequest.new(body)

        challenge = OtpChallenge.authenticate(request.otp_challenge_token)
        raise ApiError.new(:invalid_otp) unless challenge

        user = challenge.user
        raise ApiError.new(:invalid_otp) unless user.verify_otp(request.code)

        challenge.consume!
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
