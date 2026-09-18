# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CustomersController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action :set_customer, only: %i[show update grant_points]
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[update grant_points]

        def index
          dataset = filtered_customers_dataset
          pagy, customers = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { customers: CustomerResource.new(customers).to_h, meta: meta_for(pagy) }
        end

        def export
          send_data Exports::CsvBuilder.build(filtered_customers_dataset, foreign_keys: { membership_tier_id: MembershipTier }),
                     type: "text/csv",
                     filename: export_filename(current_project.name, "customers", ext: "csv"),
                     disposition: "attachment"
        end

        def show
          render json: CustomerResource.new(@customer).to_h.merge(
            stats: customer_stats,
            loyalty_point_lots: loyalty_point_lots,
            activity: Customers::ActivityFeedService.new(customer: @customer).call
          )
        end

        def update
          request = CustomerUpdateRequest.new(body)
          tier = find_membership_tier!(request.membership_tier_id) if request.attributes.key?(:membership_tier_id) && request.membership_tier_id
          customer = Customers::UpdateService.new(customer: @customer, request: request, membership_tier: tier).call
          render json: CustomerResource.new(customer).to_h
        end

        def grant_points
          request = CustomerGrantPointsRequest.new(body)
          Customers::GrantPointsService.new(
            customer: @customer, points: request.points, expires_at: request.expires_at,
            reason: request.reason, performed_by: current_user
          ).call
          render json: CustomerResource.new(@customer).to_h.merge(
            stats: customer_stats,
            loyalty_point_lots: loyalty_point_lots,
            activity: Customers::ActivityFeedService.new(customer: @customer).call
          )
        end

        private

        def find_membership_tier!(tier_id)
          tier = MembershipTier.first(public_id: tier_id)
          unless tier && tier.membership_scheme.project_id == current_project.id
            raise ValidationError.new(details: [{ field: "membership_tier_id", message: "does not refer to an existing tier" }])
          end

          tier
        end

        # Computed via aggregate queries (not derived from a paginated orders list) so
        # these stay correct regardless of how many orders the customer actually has.
        # points_balance is the real spendable figure (non-expired lot remainders) —
        # it can be less than earned-minus-redeemed once anything has expired.
        def customer_stats
          orders = @customer.orders_dataset
          earned = @customer.loyalty_point_lots_dataset.sum(:points) || 0
          redeemed = PointsRedemption.where(customer_id: @customer.id).sum(:points_redeemed) || 0
          balance = @customer.loyalty_points_balance
          {
            order_count: orders.count,
            total_spent: (orders.sum(:total_amount) || 0).to_s,
            total_discount: (orders.sum(:total_discount_amount) || 0).to_s,
            total_points_earned: earned,
            total_points_redeemed: redeemed,
            total_points_expired: [earned - redeemed - balance, 0].max,
            points_balance: balance
          }
        end

        def loyalty_point_lots
          lots = @customer.loyalty_point_lots_dataset.order(Sequel.desc(:earned_at)).limit(100).all
          LoyaltyPointLotResource.new(lots).to_h
        end

        def set_customer
          @customer = current_project.customers_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @customer
        end

        def filtered_customers_dataset
          dataset = current_project.customers_dataset.order(Sequel.desc(:id))
          if params[:q].present?
            dataset = dataset.where(
              Sequel.ilike(:external_id, "%#{params[:q]}%") |
              Sequel.ilike(:name, "%#{params[:q]}%") |
              Sequel.ilike(:email, "%#{params[:q]}%")
            )
          end
          dataset
        end
      end
    end
  end
end
