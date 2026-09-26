require "rails_helper"

RSpec.describe Account do
  let(:record) { create(:account) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :otp_required
end
