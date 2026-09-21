# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        before_action :require_project_context!

        REFUNDED = ->(od) { od.refunded? }
        CANCELLED = ->(order) { order.cancelled_at.present? }

        def coupons
          from, to = parse_range!
          discount_ids = current_project.discounts_dataset.where(kind: "coupon").select(:id)

          series = Analytics::DailySeriesService.new(from: from, to: to)
                                                 .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { 1 }
          previous_total = previous_period_order_discount_total(discount_ids, from, to) { 1 }

          render json: {
            summary: {
              total_coupons: current_project.discounts_dataset.where(kind: "coupon").count,
              total_redemptions: series.sum { |s| s[:value] }
            },
            series: series,
            previous_period: { total_redemptions: previous_total }
          }
        end

        def promotions
          from, to = parse_range!
          discount_ids = current_project.discounts_dataset.where(kind: "promotion").select(:id)

          usage_series = Analytics::DailySeriesService.new(from: from, to: to)
                                                        .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { 1 }
          earnings_series = Analytics::DailySeriesService.new(from: from, to: to)
                                                           .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { |od| (od.amount_off || 0).to_f }
          previous_earnings_total = previous_period_order_discount_total(discount_ids, from, to) { |od| (od.amount_off || 0).to_f }

          running_promotions = current_project.discounts_dataset.where(kind: "promotion", enabled: true).all.count(&:active?)

          render json: {
            summary: {
              total_running_promotions: running_promotions,
              total_discounts_from_promotions: earnings_series.sum { |s| s[:value].to_f }
            },
            usage_series: usage_series,
            earnings_series: earnings_series,
            previous_period: { total_discounts_from_promotions: previous_earnings_total }
          }
        end

        def loyalty
          from, to = parse_range!
          discount_ids = current_project.discounts_dataset.where(kind: "loyalty").select(:id)

          series = Analytics::DailySeriesService.new(from: from, to: to)
                                                 .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { |od| od.loyalty_point_lot&.points || 0 }
          previous_total = previous_period_order_discount_total(discount_ids, from, to) { |od| od.loyalty_point_lot&.points || 0 }

          render json: {
            summary: { total_redemption_quantity: series.sum { |s| s[:value] } },
            series: series,
            previous_period: { total_redemption_quantity: previous_total }
          }
        end

        # Not date-range scoped — a live snapshot of currently-active loyalty
        # point lots, not a period question. Returned in full (no server-side
        # pagination) — this app's own BaseTable already paginates client-side
        # over whatever it's handed, matching every other admin list view here.
        def loyalty_active_redemptions
          lots = LoyaltyPointLot.where(customer_id: current_project.customers_dataset.select(:id)).all
          active_lots = lots.select { |lot| lot.status == "active" && lot.points_remaining.positive? }

          render json: {
            active_redemptions: active_lots.map do |lot|
              {
                id: lot.public_id,
                customer: { id: lot.customer.public_id, external_id: lot.customer.external_id, name: lot.customer.name },
                quantity: lot.points_remaining,
                expires_at: lot.expires_at
              }
            end
          }
        end

        def customers
          from, to = parse_range!

          series = Analytics::DailySeriesService.new(from: from, to: to).series(customers_in(from, to)) { 1 }
          new_customers = series.sum { |s| s[:value] }
          prev_from, prev_to = previous_range(from, to)
          previous_new_customers = Analytics::DailySeriesService.new(from: prev_from, to: prev_to).total(customers_in(prev_from, prev_to)) { 1 }

          render json: {
            summary: {
              total_customers: current_project.customers_dataset.count,
              active_customers: active_customers_count,
              total_spent: (Order.where(project_id: current_project.id).sum(:total_amount) || 0).to_f,
              new_customers: new_customers
            },
            series: series,
            previous_period: { new_customers: previous_new_customers }
          }
        end

        # Project-wide equivalent of #coupons/#promotions (which scope to one
        # kind) — same dual-series shape as #promotions (redemptions +
        # discounted amount, both refund-aware), just across every discount
        # kind at once, for the campaigns list's own totals/graph.
        def campaigns
          from, to = parse_range!
          discount_ids = current_project.discounts_dataset.select(:id)

          usage_series = Analytics::DailySeriesService.new(from: from, to: to)
                                                        .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { 1 }
          earnings_series = Analytics::DailySeriesService.new(from: from, to: to)
                                                           .series(order_discounts_in(discount_ids, from, to), exclude: REFUNDED) { |od| (od.amount_off || 0).to_f }
          previous_redemptions_total = previous_period_order_discount_total(discount_ids, from, to) { 1 }
          previous_discounted_total = previous_period_order_discount_total(discount_ids, from, to) { |od| (od.amount_off || 0).to_f }

          render json: {
            summary: {
              total_campaigns: current_project.campaigns_dataset.count,
              active_campaigns: current_project.campaigns_dataset.all.count(&:active?),
              total_redemptions: usage_series.sum { |s| s[:value] },
              total_discounted_amount: earnings_series.sum { |s| s[:value].to_f }
            },
            usage_series: usage_series,
            earnings_series: earnings_series,
            previous_period: { total_redemptions: previous_redemptions_total, total_discounted_amount: previous_discounted_total }
          }
        end

        # Orders-per-day / revenue-per-day for the orders list's totals/graph.
        # total_orders counts every order in range regardless of status;
        # revenue and discount-given exclude cancelled orders (never a
        # completed sale) via CANCELLED — refunded/partially-refunded orders
        # still count their full total_amount, since Order has no stored
        # net-of-refund total to report instead.
        def orders
          from, to = parse_range!

          orders_series = Analytics::DailySeriesService.new(from: from, to: to).series(orders_in(from, to)) { 1 }
          revenue_series = Analytics::DailySeriesService.new(from: from, to: to)
                                                          .series(orders_in(from, to), exclude: CANCELLED) { |o| o.total_amount.to_f }

          total_orders = orders_series.sum { |s| s[:value] }
          total_revenue = revenue_series.sum { |s| s[:value].to_f }
          total_discount_given = Analytics::DailySeriesService.new(from: from, to: to)
                                                                .total(orders_in(from, to), exclude: CANCELLED) { |o| o.total_discount_amount.to_f }

          previous_total_orders = previous_period_order_total(from, to) { 1 }
          previous_total_revenue = previous_period_order_total(from, to, exclude: CANCELLED) { |o| o.total_amount.to_f }
          previous_total_discount_given = previous_period_order_total(from, to, exclude: CANCELLED) { |o| o.total_discount_amount.to_f }

          render json: {
            summary: {
              total_orders: total_orders,
              total_revenue: total_revenue,
              total_discount_given: total_discount_given,
              average_order_value: total_orders.positive? ? (total_revenue / total_orders) : 0
            },
            orders_series: orders_series,
            revenue_series: revenue_series,
            previous_period: {
              total_orders: previous_total_orders,
              total_revenue: previous_total_revenue,
              total_discount_given: previous_total_discount_given
            }
          }
        end

        private

        def orders_in(from, to)
          current_project.orders_dataset.where(created_at: day_range(from, to))
        end

        def previous_period_order_total(from, to, exclude: Analytics::DailySeriesService::NEVER_EXCLUDE, &block)
          prev_from, prev_to = previous_range(from, to)
          Analytics::DailySeriesService.new(from: prev_from, to: prev_to)
                                        .total(orders_in(prev_from, prev_to), exclude: exclude, &block)
        end

        def order_discounts_in(discount_ids, from, to)
          OrderDiscount.where(discount_id: discount_ids, created_at: day_range(from, to))
        end

        def previous_period_order_discount_total(discount_ids, from, to, &block)
          prev_from, prev_to = previous_range(from, to)
          Analytics::DailySeriesService.new(from: prev_from, to: prev_to)
                                        .total(order_discounts_in(discount_ids, prev_from, prev_to), exclude: REFUNDED, &block)
        end

        def customers_in(from, to)
          current_project.customers_dataset.where(created_at: day_range(from, to))
        end

        # Distinct customers with at least one order in the trailing 30 days —
        # a fixed window independent of whatever date range is selected in the
        # dashboard's own picker (this is a standing "is this customer active
        # right now" definition, not a report-period question), per the spec's
        # own suggested default. No existing app-wide "active customer"
        # definition exists anywhere else in this codebase to defer to instead.
        def active_customers_count
          recent_customer_ids = Order.where(project_id: current_project.id, created_at: (Time.now.utc - 30 * 24 * 60 * 60)..)
                                      .select(:customer_id)
          current_project.customers_dataset.where(id: recent_customer_ids).count
        end

        def day_range(from, to)
          Time.utc(from.year, from.month, from.day)...Time.utc((to + 1).year, (to + 1).month, (to + 1).day)
        end

        def previous_range(from, to)
          length = (to - from).to_i + 1
          prev_to = from - 1
          prev_from = prev_to - length + 1
          [prev_from, prev_to]
        end

        def parse_range!
          from = Date.iso8601(params[:from])
          to = Date.iso8601(params[:to])
          raise ValidationError.new(details: [{ field: "to", message: "must not be before from" }]) if to < from

          [from, to]
        rescue ArgumentError, TypeError
          raise ValidationError.new(details: [{ field: "base", message: "from and to must be valid ISO dates (YYYY-MM-DD)" }])
        end
      end
    end
  end
end
