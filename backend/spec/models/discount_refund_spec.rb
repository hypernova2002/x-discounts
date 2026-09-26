require "rails_helper"

RSpec.describe DiscountRefund do
  let(:record) { create(:discount_refund) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :amount_off, min: 0, max: 100_000_000
  it_behaves_like "a utf8-length-bounded field", :reason, max: 10_000
end
