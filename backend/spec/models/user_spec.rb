require "rails_helper"

RSpec.describe User do
  let(:record) { create(:user) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :otp_enabled

  describe "email length (format-constrained, so boundary values stay email-shaped)" do
    def email_of_length(length)
      "#{"a" * (length - "@x.com".length)}@x.com"
    end

    it "accepts an email at the 255-character limit" do
      record.email = email_of_length(255)
      record.valid?
      expect(Array(record.errors[:email])).to be_empty
    end

    it "rejects an email one character over the 255-character limit" do
      record.email = email_of_length(256)
      record.valid?
      expect(Array(record.errors[:email])).not_to be_empty
    end
  end
end
