require "rails_helper"

RSpec.describe Project do
  let(:record) { create(:project) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
end
