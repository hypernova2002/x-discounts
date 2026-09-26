require "rails_helper"

RSpec.describe Customer do
  let(:record) { create(:customer) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :external_id, max: 255
  it_behaves_like "a utf8-length-bounded field", :email, max: 255
  it_behaves_like "a utf8-length-bounded field", :phone_number, max: 255
  it_behaves_like "a utf8-length-bounded field", :country, max: 255
  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :marketing_opt_in

  describe "date_of_birth" do
    it "accepts a date in the past" do
      record.date_of_birth = Date.new(1990, 1, 1)
      record.valid?
      expect(Array(record.errors[:date_of_birth])).to be_empty
    end

    it "accepts today's date" do
      record.date_of_birth = Date.today
      record.valid?
      expect(Array(record.errors[:date_of_birth])).to be_empty
    end

    it "rejects a date in the future" do
      record.date_of_birth = Date.today + 1
      record.valid?
      expect(Array(record.errors[:date_of_birth])).not_to be_empty
    end
  end
end
