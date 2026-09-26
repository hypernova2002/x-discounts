require "rails_helper"

RSpec.describe Order do
  let(:record) { create(:order) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :total_amount, min: 0, max: 100_000_000
  it_behaves_like "a bounded numeric field", :total_discount_amount, min: 0, max: 100_000_000
end
