require "rails_helper"

RSpec.describe MembershipTier do
  let(:record) { create(:membership_tier) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a bounded numeric field", :rank, min: 0, max: 10_000, integer_only: true
  it_behaves_like "a bounded numeric field", :grace_period_days, min: 1, max: 10_000, integer_only: true
end
