require "rails_helper"

RSpec.describe Campaign do
  let(:record) { create(:campaign) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :enabled
  it_behaves_like "a boolean-typed field", :archived
end
