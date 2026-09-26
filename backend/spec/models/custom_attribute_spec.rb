require "rails_helper"

RSpec.describe CustomAttribute do
  let(:record) { create(:custom_attribute) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :key, max: 255
end
