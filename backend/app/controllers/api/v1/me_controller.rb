# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      def show
        render json: {
          project: current_project ? MinimalProjectResource.new(current_project).to_h : nil,
          user: MinimalUserResource.new(current_user).to_h,
          role: current_role,
          otp_required: current_user.account.otp_required
        }
      end

      def update_password
        request = ChangePasswordRequest.new(body)
        raise ApiError.new(:invalid_credentials) unless current_user.authenticate(request.current_password)

        current_user.password = request.new_password
        current_user.password_confirmation = request.new_password_confirmation
        raise ValidationError.from_model(current_user) unless current_user.valid?

        current_user.save
        head :no_content
      end

      def otp_setup
        current_user.generate_otp_secret!
        render json: { secret: current_user.otp_secret, provisioning_uri: current_user.otp_provisioning_uri }
      end

      def otp_enable
        request = OtpEnableRequest.new(body)
        unless current_user.otp_secret && ROTP::TOTP.new(current_user.otp_secret).verify(request.code, drift_behind: 30, drift_ahead: 30)
          raise ApiError.new(:invalid_otp)
        end

        backup_codes = current_user.enable_otp!
        render json: { user: UserResource.new(current_user).to_h, backup_codes: backup_codes }
      end

      def otp_disable
        request = OtpDisableRequest.new(body)
        raise ApiError.new(:invalid_credentials) unless current_user.authenticate(request.current_password)
        raise ApiError.new(:otp_required_by_account) if current_user.account.otp_required

        current_user.disable_otp!
        render json: UserResource.new(current_user).to_h
      end
    end
  end
end
