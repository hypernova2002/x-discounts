# frozen_string_literal: true

# The periodic half of tier evaluation — RedeemService re-evaluates a customer right
# after their own order, but a time-windowed requirement (e.g. "spent $500 in the
# last 30 days") can fall out of range purely from time passing with no new order at
# all, which only a scheduled sweep like this one catches. Nothing in this codebase
# schedules it yet (no cron gem is installed) — wiring that up (sidekiq-cron,
# whenever, or a system crontab hitting `rails runner`) is a deploy-time concern.
class MembershipTierSweepJob < ApplicationJob
  queue_as :default

  def perform(project_id: nil)
    scope = project_id ? Customer.where(project_id: project_id) : Customer.dataset
    scope.each do |customer|
      Memberships::EvaluateCustomerService.new(customer: customer).call
    end
  end
end
