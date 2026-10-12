# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::ActivityFeedService do
  let(:customer) { create(:customer) }

  describe "#call" do
    it "merges orders, gift shop redemptions, and a membership event, sorted most-recent-first" do
      order = create(:order, project: customer.project, customer: customer, created_at: Time.utc(2026, 1, 1))
      create(:gift_shop_redemption, customer: customer, redeemed_at: Time.utc(2026, 2, 1))
      tier = create(:membership_tier)
      customer.update(membership_tier: tier, membership_tier_entered_at: Time.utc(2026, 3, 1))

      events = described_class.new(customer: customer).call

      expect(events.map { |e| e[:type] }).to eq(%w[membership gift_shop_redemption order])
      expect(events.last[:order_id]).to eq(order.public_id)
    end

    it "omits the membership event when the customer has no membership tier" do
      events = described_class.new(customer: customer).call

      expect(events).to be_empty
    end

    it "bounds each source query to LIMIT regardless of how many rows exist, keeping only the most recent" do
      stub_const("Customers::ActivityFeedService::LIMIT", 3)
      5.times { |i| create(:order, project: customer.project, customer: customer, created_at: Time.utc(2026, 1, 1 + i)) }

      events = described_class.new(customer: customer).call

      expect(events.size).to eq(3)
      expect(events.map { |e| e[:order_id] }).to eq(
        customer.orders_dataset.order(Sequel.desc(:created_at)).limit(3).select_map(:public_id)
      )
    end
  end
end
