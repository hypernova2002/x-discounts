# frozen_string_literal: true

module Api
  module V1
    module Admin
      class OrdersController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        EAGER = [:customer, :order_line_items, { order_discounts: [:discount, :loyalty_point_lot] }, :points_redemption].freeze

        before_action :require_project_context!
        before_action :set_order, only: %i[show cancel]
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[cancel]

        def index
          dataset = filtered_orders_dataset.eager(*EAGER)
          pagy, orders = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { orders: OrderResource.new(orders).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: OrderResource.new(@order).to_h
        end

        def export
          send_data Exports::CsvBuilder.build(filtered_orders_dataset, foreign_keys: { customer_id: Customer }),
                     type: "text/csv",
                     filename: export_filename(current_project.name, "orders", ext: "csv"),
                     disposition: "attachment"
        end

        def cancel
          request = OrderCancelRequest.new(body)
          order = Orders::CancelService.new(order: @order, refund: request.refund, reason: request.reason, performed_by: current_user).call
          render json: OrderResource.new(order).to_h
        end

        private

        def set_order
          @order = current_project.orders_dataset.eager(*EAGER).first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @order
        end

        def filtered_orders_dataset
          dataset = current_project.orders_dataset.order(Sequel.desc(:id))
          dataset = dataset.where(customer_id: current_project.customers_dataset.where(external_id: params[:customer_external_id]).select(:id)) if params[:customer_external_id].present?
          dataset
        end
      end
    end
  end
end
