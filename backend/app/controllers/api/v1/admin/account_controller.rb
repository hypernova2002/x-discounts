# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AccountController < BaseController
        before_action -> { require_account_admin! }, only: %i[update]

        def show
          render json: AccountResource.new(current_user.account).to_h
        end

        def update
          account = current_user.account
          account.set(name: body.key?(:name) ? body[:name] : account.name)
          raise ValidationError.from_model(account) unless account.valid?

          account.save
          render json: AccountResource.new(account).to_h
        end
      end
    end
  end
end
