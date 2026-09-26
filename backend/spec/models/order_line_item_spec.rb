require "rails_helper"

RSpec.describe OrderLineItem do
  let(:record) { create(:order_line_item) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :sku, max: 255
  it_behaves_like "a bounded numeric field", :quantity, min: 1, max: 100_000, integer_only: true
  it_behaves_like "a bounded numeric field", :unit_price, min: 0, max: 100_000_000
end
