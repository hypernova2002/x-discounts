require "rails_helper"

RSpec.describe LoyaltyPointLedgerEntry do
  let(:record) { create(:loyalty_point_ledger_entry) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a bounded numeric field", :delta, min: -10_000_000, max: -1, integer_only: true
  it_behaves_like "a utf8-length-bounded field", :reason, max: 10_000
end
