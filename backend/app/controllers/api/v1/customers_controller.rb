# frozen_string_literal: true

module Api
  module V1
    class CustomersController < ApplicationController
      before_action :require_project_context!
      before_action :set_customer, only: %i[show]

      def create
        request = CustomerRequest.new(body)
        customer = Customers::CreateService.new(project: current_project, attrs: request.attributes).call
        render json: CustomerResource.new(customer).to_h, status: :created
      end

      def show
        render json: CustomerResource.new(@customer).to_h
      end

      private

      def set_customer
        @customer = current_project.customers_dataset.first(public_id: params[:id])
        raise ApiError.new(:not_found) unless @customer
      end
    end
  end
end
