# frozen_string_literal: true

module Api
  module V1
    module Admin
      class AnalyticsController < BaseController
        before_action :require_project_context!

        # How many days out counts as "ending soon" for the dashboard's needs-
        # attention list — matches lib/lifecycleStatus.js's own
        # ENDS_SOON_THRESHOLD_DAYS convention on the frontend.
        ENDING_SOON_DAYS = 14
        # Comfortably covers every existing frontend preset (DateRangePicker.vue's
        # largest is 90 days) plus any reasonable custom pick, while bounding the
        # worst case for the grouped SUM queries below.
        MAX_RANGE_DAYS = 366

        def coupons
          from, to = parse_range!
          discount_ids = current_project.discounts_dataset.where(kind: "coupon").select(:id)

          series = Analytics::DailySeriesService.new(from: from, to: to).series(order_discounts_in(discount_ids, from, to))
          previous_total = previous_period_order_discount_total(discount_ids, from, to)

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
          dataset = order_discounts_in(discount_ids, from, to)

          usage_series = Analytics::DailySeriesService.new(from: from, to: to).series(dataset)
          earnings_series = Analytics::DailySeriesService.new(from: from, to: to).series(dataset, value: :amount_off)
          previous_earnings_total = previous_period_order_discount_total(discount_ids, from, to, value: :amount_off)

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
          points_value = Sequel[:loyalty_point_lots][:points]

          series = Analytics::DailySeriesService.new(from: from, to: to)
                                                 .series(order_discounts_with_points_in(discount_ids, from, to),
                                                         value: points_value, date_column: Sequel[:order_discounts][:created_at])
          prev_from, prev_to = previous_range(from, to)
          previous_total = Analytics::DailySeriesService.new(from: prev_from, to: prev_to)
                                                          .total(order_discounts_with_points_in(discount_ids, prev_from, prev_to), value: points_value)

          total_points_redeemed = points_redeemed_total(discount_ids, from, to)
          previous_points_redeemed = points_redeemed_total(discount_ids, prev_from, prev_to)

          render json: {
            summary: {
              total_redemption_quantity: series.sum { |s| s[:value] },
              total_points_redeemed: total_points_redeemed
            },
            series: series,
            previous_period: { total_redemption_quantity: previous_total, total_points_redeemed: previous_points_redeemed }
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

        # Not date-range scoped — a live snapshot, same shape as
        # #loyalty_active_redemptions. valid_until/active_until are jsonb-backed
        # accessors on Discount (see Discount#valid_until/#active_until), not
        # real columns, so — consistent with how #active_campaigns and
        # #running_promotions above already work — this loads enabled
        # campaigns/discounts and filters with those existing accessors in Ruby
        # rather than a SQL range query.
        def attention
          now = Time.now.utc
          soon = now + (ENDING_SOON_DAYS * 24 * 60 * 60)
          ending_soon = ->(until_at) { until_at && until_at > now && until_at <= soon }

          campaigns = current_project.campaigns_dataset.where(enabled: true, archived: false).all
                                      .select { |c| ending_soon.call(c.valid_until) }

          discounts = current_project.discounts_dataset.where(enabled: true).all
                                      .select { |d| ending_soon.call(d.kind == "coupon" ? d.valid_until : d.active_until) }

          render json: {
            campaigns: campaigns.map { |c| { id: c.public_id, name: c.name, until: c.valid_until } },
            discounts: discounts.map do |d|
              {
                id: d.public_id,
                name: d.name,
                kind: d.kind,
                until: d.kind == "coupon" ? d.valid_until : d.active_until,
                campaign: { id: d.campaign.public_id, name: d.campaign.name }
              }
            end
          }
        end

        def customers
          from, to = parse_range!

          series = Analytics::DailySeriesService.new(from: from, to: to).series(customers_in(from, to))
          new_customers = series.sum { |s| s[:value] }
          prev_from, prev_to = previous_range(from, to)
          previous_new_customers = Analytics::DailySeriesService.new(from: prev_from, to: prev_to).total(customers_in(prev_from, prev_to))

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
          dataset = order_discounts_in(discount_ids, from, to)

          usage_series = Analytics::DailySeriesService.new(from: from, to: to).series(dataset)
          earnings_series = Analytics::DailySeriesService.new(from: from, to: to).series(dataset, value: :amount_off)
          previous_redemptions_total = previous_period_order_discount_total(discount_ids, from, to)
          previous_discounted_total = previous_period_order_discount_total(discount_ids, from, to, value: :amount_off)

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
        # completed sale) via not_cancelled — refunded/partially-refunded
        # orders still count their full total_amount, since Order has no
        # stored net-of-refund total to report instead.
        def orders
          from, to = parse_range!

          orders_series = Analytics::DailySeriesService.new(from: from, to: to).series(orders_in(from, to))
          revenue_series = Analytics::DailySeriesService.new(from: from, to: to).series(not_cancelled(orders_in(from, to)), value: :total_amount)

          total_orders = orders_series.sum { |s| s[:value] }
          total_revenue = revenue_series.sum { |s| s[:value].to_f }
          total_discount_given = Analytics::DailySeriesService.new(from: from, to: to)
                                                                .total(not_cancelled(orders_in(from, to)), value: :total_discount_amount)

          previous_total_orders = previous_period_order_total(from, to)
          previous_total_revenue = previous_period_order_total(from, to, cancelled_excluded: true, value: :total_amount)
          previous_total_discount_given = previous_period_order_total(from, to, cancelled_excluded: true, value: :total_discount_amount)

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

        def not_cancelled(dataset)
          dataset.where(cancelled_at: nil)
        end

        def previous_period_order_total(from, to, cancelled_excluded: false, value: 1)
          prev_from, prev_to = previous_range(from, to)
          dataset = orders_in(prev_from, prev_to)
          dataset = not_cancelled(dataset) if cancelled_excluded
          Analytics::DailySeriesService.new(from: prev_from, to: prev_to).total(dataset, value: value)
        end

        # Points actually spent (checkout or gift shop) in the range, for lots
        # earned via this project's loyalty discounts — mirrors
        # Discount#points_redeemed's "spend, not clawback" distinction, just
        # scoped to a date range and summed across every loyalty discount
        # instead of one.
        def points_redeemed_total(discount_ids, from, to)
          lot_ids = LoyaltyPointLot.where(discount_id: discount_ids).select(:id)
          entries = LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: lot_ids, kind: "spend", created_at: day_range(from, to))
          -(entries.sum(:delta) || 0)
        end

        # Columns qualified to order_discounts explicitly — #loyalty joins this
        # dataset to loyalty_point_lots, which has its own discount_id and
        # created_at columns, and an unqualified WHERE would be ambiguous.
        def order_discounts_in(discount_ids, from, to)
          OrderDiscount.excluding_refunded(
            OrderDiscount.where(Sequel[:order_discounts][:discount_id] => discount_ids, Sequel[:order_discounts][:created_at] => day_range(from, to))
          )
        end

        def order_discounts_with_points_in(discount_ids, from, to)
          order_discounts_in(discount_ids, from, to).left_join(:loyalty_point_lots, id: :loyalty_point_lot_id)
        end

        def previous_period_order_discount_total(discount_ids, from, to, value: 1)
          prev_from, prev_to = previous_range(from, to)
          Analytics::DailySeriesService.new(from: prev_from, to: prev_to)
                                        .total(order_discounts_in(discount_ids, prev_from, prev_to), value: value)
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
          if (to - from).to_i + 1 > MAX_RANGE_DAYS
            raise ValidationError.new(details: [{ field: "base", message: "date range must not exceed #{MAX_RANGE_DAYS} days" }])
          end

          [from, to]
        rescue ArgumentError, TypeError
          raise ValidationError.new(details: [{ field: "base", message: "from and to must be valid ISO dates (YYYY-MM-DD)" }])
        end
      end
    end
  end
end
