require "rails_helper"

RSpec.describe GiftShopRedemption do
  let(:record) { create(:gift_shop_redemption) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :item_name, max: 1000
  it_behaves_like "a bounded numeric field", :quantity, min: 1, max: 100_000, integer_only: true
  it_behaves_like "a bounded numeric field", :points_spent, min: 0, max: 10_000_000, integer_only: true
end
