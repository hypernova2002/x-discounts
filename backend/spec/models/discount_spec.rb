require "rails_helper"

RSpec.describe Discount do
  let(:record) { create(:discount) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a utf8-length-bounded field", :key, max: 255
  it_behaves_like "a boolean-typed field", :stackable
  it_behaves_like "a boolean-typed field", :refundable
  it_behaves_like "a boolean-typed field", :enabled
  it_behaves_like "a bounded numeric field", :max_redemptions, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemptions_per_customer, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemptions_per_day, min: 1, max: 1_000_000, integer_only: true
  it_behaves_like "a bounded numeric field", :max_redemption_amount, min: 0, max: 100_000_000
  it_behaves_like "a bounded numeric field", :max_redemption_amount_per_day, min: 0, max: 100_000_000
  it_behaves_like "a bounded numeric field", :max_redemption_amount_per_customer, min: 0, max: 100_000_000

  describe "kind_config sub-fields" do
    it "accepts a design_html at the 10000-character limit" do
      record.kind_config = { "design_html" => "a" * 10_000 }
      record.valid?
      expect(Array(record.errors[:kind_config])).to be_empty
    end

    it "rejects a design_html over the 10000-character limit" do
      record.kind_config = { "design_html" => "a" * 10_001 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a design_image_filename over the 255-character limit" do
      record.kind_config = { "design_image_filename" => "a" * 256 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a design_image_content_type over the 255-character limit" do
      record.kind_config = { "design_image_content_type" => "a" * 256 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "accepts points_expire_after_days at the 10000 boundary" do
      record.kind_config = { "points_expire_after_days" => 10_000 }
      record.valid?
      expect(Array(record.errors[:kind_config])).to be_empty
    end

    it "rejects points_expire_after_days over 10000" do
      record.kind_config = { "points_expire_after_days" => 10_001 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a negative points_expire_after_days" do
      record.kind_config = { "points_expire_after_days" => -1 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end

    it "rejects a non-integer points_expire_after_days" do
      record.kind_config = { "points_expire_after_days" => 5.5 }
      record.valid?
      expect(Array(record.errors[:kind_config])).not_to be_empty
    end
  end
end
