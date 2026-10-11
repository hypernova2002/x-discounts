# frozen_string_literal: true

module Analytics
  # Buckets a set of rows by day via a single grouped SQL query — shared by
  # every analytics dashboard.
  class DailySeriesService
    def initialize(from:, to:)
      @from = from
      @to = to
    end

    # dataset: a Sequel dataset already scoped to the project + created_at
    # BETWEEN from/to, any exclusion filter (e.g. OrderDiscount.excluding_refunded),
    # and any join `value`/`date_column` reads from. Returns one entry per
    # calendar day in range, in order, zero-filled for days with no activity.
    # `value` is summed per day — pass a column (or qualified/joined column)
    # to total it, or leave the default 1 to count rows.
    def series(dataset, value: 1, date_column: :created_at)
      day = Sequel.function(:date_trunc, "day", Sequel.cast(date_column, :timestamp)).cast(:date)
      totals = dataset.group(day).select(day.as(:day), Sequel.function(:sum, value).as(:total)).to_hash(:day, :total)
      (@from..@to).map { |date| { date: date.iso8601, value: numeric(totals[date]) } }
    end

    # A flat sum over a (typically different, e.g. the preceding period)
    # dataset — used for the previous-period comparison total, which doesn't
    # need day-by-day buckets, just the one number.
    def total(dataset, value: 1)
      numeric(dataset.get(Sequel.function(:sum, value)))
    end

    private

    # Always coerced to a real Float (never a bare BigDecimal) — Rails'
    # default JSON serialization renders BigDecimal as a *string*, and the
    # frontend's analytics.ts schemas require z.number() for every one of
    # these fields. SUM already ignores NULL rows (equivalent to treating a
    # NULL amount_off as 0), so no separate COALESCE is needed anywhere this
    # is called.
    def numeric(value)
      value.nil? ? 0.0 : value.to_f
    end
  end
end
