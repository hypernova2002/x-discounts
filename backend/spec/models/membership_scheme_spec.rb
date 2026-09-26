require "rails_helper"

RSpec.describe MembershipScheme do
  let(:record) { create(:membership_scheme) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
end
