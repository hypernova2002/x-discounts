require "rails_helper"

RSpec.describe GiftShopItem do
  let(:record) { create(:gift_shop_item) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a utf8-length-bounded field", :description, max: 10_000
  it_behaves_like "a utf8-length-bounded field", :photo_filename, max: 255
  it_behaves_like "a utf8-length-bounded field", :photo_content_type, max: 255
  it_behaves_like "a bounded numeric field", :points_cost, min: 1, max: 10_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :stock, min: 0, max: 10_000_000, integer_only: true
  it_behaves_like "a boolean-typed field", :enabled
end
