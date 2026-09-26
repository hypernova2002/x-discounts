require "rails_helper"

RSpec.describe LoyaltyPointLot do
  let(:record) { create(:loyalty_point_lot) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :points, min: 0, max: 10_000_000, integer_only: true
  it_behaves_like "a utf8-length-bounded field", :reason, max: 10_000
end
