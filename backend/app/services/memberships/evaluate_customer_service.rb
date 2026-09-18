# frozen_string_literal: true

module Memberships
  # Determines and applies the customer's best-qualifying tier across every
  # membership scheme in their project, persisting it only if it's actually changed.
  #
  # Only tiers with requirements_condition set (MembershipTier#auto_assignable?)
  # ever participate — a tier left blank is presumed manually-managed and is never
  # assigned to, or taken away from, a customer by this. Within a scheme, the
  # highest-rank tier whose requirements are currently met wins. If no
  # auto-assignable tier matches, the customer keeps whatever they have — UNLESS
  # their current tier is itself auto-assignable and no longer matches, in which
  # case they drop out of it (to a lower auto-tier that still matches, or to no
  # membership at all).
  #
  # Crucially, a customer already in a scheme (whether they got there manually or
  # automatically) is only ever re-evaluated against *that same scheme* — never
  # moved into a different scheme they were never part of just because they happen
  # to numerically qualify for one of its tiers too. Only a customer with no tier
  # at all gets scanned against every scheme in the project, to discover which one
  # (if any) they now newly qualify for.
  #
  # A tier's own grace_period_days protects against DEMOTION only, measured from
  # membership_tier_entered_at — a customer can always be promoted further up
  # immediately, but won't be moved down (or out of membership) until that many days
  # have passed since they entered their current tier, even if they'd otherwise no
  # longer qualify for it. This is what avoids "demoted the week after a big
  # purchase ages out of the window" churn.
  class EvaluateCustomerService
    def initialize(customer:, now: Time.now.utc)
      @customer = customer
      @now = now
    end

    def call
      new_tier = best_matching_tier
      return @customer if new_tier.nil? && !current_tier_auto_assignable?
      return @customer if @customer.membership_tier_id == new_tier&.id
      return @customer if within_grace_period?(new_tier)

      @customer.update(membership_tier: new_tier, membership_tier_entered_at: @now)
    end

    private

    def within_grace_period?(new_tier)
      current = @customer.membership_tier
      return false unless current

      new_rank = new_tier&.rank || -Float::INFINITY
      return false if new_rank >= current.rank

      grace_days = current.grace_period_days
      entered_at = @customer.membership_tier_entered_at
      return false unless grace_days && entered_at

      @now < entered_at + grace_days.days
    end

    def current_tier_auto_assignable?
      @customer.membership_tier&.auto_assignable? || false
    end

    def best_matching_tier
      if @customer.membership_tier
        best_tier_in_scheme(@customer.membership_tier.membership_scheme)
      else
        @customer.project.membership_schemes_dataset.order(:id).each do |scheme|
          tier = best_tier_in_scheme(scheme)
          return tier if tier
        end
        nil
      end
    end

    def best_tier_in_scheme(scheme)
      evaluator = TierEvaluator.new(customer: @customer, now: @now)
      scheme.membership_tiers_dataset.order(Sequel.desc(:rank)).all.find do |tier|
        tier.auto_assignable? && evaluator.evaluate(tier.requirements_condition)
      end
    end
  end
end
