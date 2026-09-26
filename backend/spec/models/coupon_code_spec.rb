require "rails_helper"

RSpec.describe CouponCode do
  let(:record) { create(:coupon) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :code, max: 255
  it_behaves_like "a bounded numeric field", :max_redemptions, min: 1, max: 10_000, integer_only: true
end
