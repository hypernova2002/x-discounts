# frozen_string_literal: true

module Analytics
  # Buckets a set of records by day and applies a per-row value block — shared by
  # every analytics dashboard. `exclude:` is an optional per-row predicate (e.g.
  # OrderDiscount#refunded? for the coupon/promotion/loyalty redemption metrics,
  # which need to exclude refunded rows — loyalty rows are refunded through a
  # ledger clawback rather than a DiscountRefund record, so keeping that
  # distinction in one place, on OrderDiscount itself, matters more than doing
  # the exclusion in SQL). Records with no refund concept at all (e.g. Customer,
  # for the new-customers-per-day chart) simply omit it.
  class DailySeriesService
    NEVER_EXCLUDE = ->(_record) { false }

    def initialize(from:, to:)
      @from = from
      @to = to
    end

    # records: a dataset already scoped to the project + created_at BETWEEN
    # from/to (plus whatever kind/entity filter the caller needs). Returns one
    # entry per calendar day in range, in order, zero-filled for days with no
    # activity.
    def series(records, exclude: NEVER_EXCLUDE)
      buckets = Hash.new(0)
      records.all.each do |record|
        next if exclude.call(record)

        buckets[record.created_at.to_date] += yield(record)
      end
      (@from..@to).map { |date| { date: date.iso8601, value: buckets[date] } }
    end

    # A flat sum over a (typically different, e.g. the preceding period)
    # dataset — used for the previous-period comparison total, which doesn't
    # need day-by-day buckets, just the one number.
    def total(records, exclude: NEVER_EXCLUDE)
      records.all.sum { |record| exclude.call(record) ? 0 : yield(record) }
    end
  end
end
