# frozen_string_literal: true

module LoyaltyPointLots
  # Bulk form of LoyaltyPointLot#points_remaining/#status — given a batch of
  # lots, returns { points_remaining:, statuses: } maps keyed by lot id, in a
  # small constant number of queries instead of one (or two) per lot.
  class BulkStatsService
    Result = Struct.new(:points_remaining, :statuses, keyword_init: true)

    def initialize(lots)
      @lots = lots
    end

    def call
      Result.new(points_remaining: points_remaining, statuses: statuses)
    end

    private

    def lot_ids
      @lot_ids ||= @lots.map(&:id)
    end

    # #points_remaining is `points + SUM(ledger_entries.delta)` per lot — one
    # grouped SQL sum for the whole batch instead of one query per lot.
    def points_remaining
      deltas = LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: lot_ids)
                                       .group(:loyalty_point_lot_id)
                                       .select(:loyalty_point_lot_id, Sequel.function(:sum, :delta).as(:total))
                                       .to_hash(:loyalty_point_lot_id, :total)
      @lots.each_with_object({}) { |lot, h| h[lot.id] = lot.points + (deltas[lot.id] || 0).to_i }
    end

    # #status's one query-issuing branch is "has a clawback entry" — fetch
    # that as a single id set for the batch; expired?/active are pure Ruby
    # date comparisons on already-loaded columns, no query either way.
    def statuses
      clawed_back = LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: lot_ids, kind: "clawback").distinct.select_map(:loyalty_point_lot_id).to_set
      now = Time.now.utc
      @lots.each_with_object({}) do |lot, h|
        h[lot.id] = clawed_back.include?(lot.id) ? "cancelled" : (lot.expired?(now) ? "expired" : "active")
      end
    end
  end
end
