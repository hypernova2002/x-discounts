# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action -> { require_account_admin! }, only: %i[create destroy]
        before_action :set_user, only: %i[show update destroy]

        def index
          dataset = current_user.account.users_dataset.order(:id)
          pagy, users = paginate(dataset)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { users: UserResource.new(users).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: UserResource.new(@user).to_h
        end

        def create
          request = UserRequest.new(body)
          user = User.new(name: request.name, email: request.email, account_id: current_user.account_id)
          raise ValidationError.from_model(user) unless user.valid?

          user.save
          render json: UserResource.new(user).to_h, status: :created
        end

        def update
          raise ApiError.new(:forbidden) unless account_admin? || @user.id == current_user.id

          @user.set(
            name: body.key?(:name) ? body[:name] : @user.name,
            email: body.key?(:email) ? body[:email] : @user.email,
            locale: body.key?(:locale) ? body[:locale] : @user.locale
          )
          raise ValidationError.from_model(@user) unless @user.valid?

          @user.save
          render json: UserResource.new(@user).to_h
        end

        def destroy
          @user.destroy
          head :no_content
        end

        private

        def set_user
          @user = current_user.account.users_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @user
        end
      end
    end
  end
end
