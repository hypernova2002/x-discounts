# frozen_string_literal: true

module Discounts
  # Resolves which of several individually-eligible promotion/coupon candidates
  # actually apply together, given `stackable` and discount_stacking_compatibilities.
  # Loyalty discounts never go through here — earning points isn't a price
  # reduction, so there's nothing to conflict over; they always combine, same as today.
  #
  # Two discounts are compatible if both are stackable:true, or if there's an explicit
  # compatibility pairing between them (an override for otherwise-exclusive
  # discounts). Resolution is greedy by value, highest first: sort candidates by
  # total discount value descending, accept each one that's compatible with every
  # candidate already accepted. This isn't a guaranteed-optimal maximum-weight-clique
  # solve, but it's the standard practical approach for this class of problem and
  # more than sufficient at the scale a single cart's eligible discounts ever reach.
  #
  # `candidates` is an array of {discount:, results:, value:}. Returns the accepted
  # subset, same shape, in descending value order.
  class StackingResolver
    def self.resolve(candidates)
      new(candidates).resolve
    end

    def initialize(candidates)
      @candidates = candidates
    end

    def resolve
      compatible_pairs = load_compatible_pairs

      accepted = []
      @candidates.sort_by { |c| -c[:value] }.each do |candidate|
        next unless accepted.all? { |a| compatible?(candidate[:discount], a[:discount], compatible_pairs) }

        accepted << candidate
      end
      accepted
    end

    private

    def load_compatible_pairs
      discount_ids = @candidates.map { |c| c[:discount].id }
      return Set.new if discount_ids.size < 2

      rows = DiscountStackingCompatibility.where(discount_id: discount_ids, compatible_discount_id: discount_ids).all
      rows.each_with_object(Set.new) { |row, set| set << [row.discount_id, row.compatible_discount_id].sort }
    end

    def compatible?(a, b, compatible_pairs)
      return true if a.stackable && b.stackable

      compatible_pairs.include?([a.id, b.id].sort)
    end
  end
end
