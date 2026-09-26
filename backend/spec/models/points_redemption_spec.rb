require "rails_helper"

RSpec.describe PointsRedemption do
  let(:record) { create(:points_redemption) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :points_redeemed, min: 0, max: 10_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :amount_off, min: 0, max: 100_000_000
end
