require "rails_helper"

RSpec.describe OrderDiscount do
  let(:record) { create(:order_discount) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :kind, max: 255
  it_behaves_like "a utf8-length-bounded field", :discount_key, max: 255
  it_behaves_like "a utf8-length-bounded field", :effect_type, max: 255
  it_behaves_like "a utf8-length-bounded field", :sku, max: 255
  it_behaves_like "a utf8-length-bounded field", :discount_name, max: 1000
  it_behaves_like "a bounded numeric field", :amount_off, min: 0, max: 100_000_000
end
