# frozen_string_literal: true

# Sequel::Model::Errors is a plain Hash, not an ActiveModel::Errors — a field with
# no errors reads back as nil, not [], so every check goes through Array(...).
RSpec.shared_examples "a utf8-length-bounded field" do |field, max:|
  it "accepts a value at the #{max}-character limit" do
    record.public_send("#{field}=", "a" * max)
    record.valid?
    expect(Array(record.errors[field])).to be_empty
  end

  it "rejects a value one character over the #{max}-character limit" do
    record.public_send("#{field}=", "a" * (max + 1))
    record.valid?
    expect(Array(record.errors[field])).not_to be_empty
  end

  it "rejects a value containing a null byte" do
    record.public_send("#{field}=", "bad\0value")
    record.valid?
    expect(Array(record.errors[field])).not_to be_empty
  end
end

RSpec.shared_examples "a boolean-typed field" do |field|
  it "accepts true" do
    record.public_send("#{field}=", true)
    record.valid?
    expect(Array(record.errors[field])).to be_empty
  end

  it "accepts false" do
    record.public_send("#{field}=", false)
    record.valid?
    expect(Array(record.errors[field])).to be_empty
  end

  it "rejects a non-boolean value" do
    record.values[field] = "not-a-boolean"
    record.valid?
    expect(Array(record.errors[field])).not_to be_empty
  end
end

RSpec.shared_examples "a bounded numeric field" do |field, min: nil, max: nil, integer_only: false|
  if min
    it "accepts the minimum value of #{min}" do
      record.public_send("#{field}=", min)
      record.valid?
      expect(Array(record.errors[field])).to be_empty
    end

    it "rejects a value below the minimum of #{min}" do
      record.public_send("#{field}=", min - 1)
      record.valid?
      expect(Array(record.errors[field])).not_to be_empty
    end
  end

  if max
    it "accepts the maximum value of #{max}" do
      record.public_send("#{field}=", max)
      record.valid?
      expect(Array(record.errors[field])).to be_empty
    end

    it "rejects a value above the maximum of #{max}" do
      record.public_send("#{field}=", max + 1)
      record.valid?
      expect(Array(record.errors[field])).not_to be_empty
    end
  end

  if integer_only
    it "rejects a non-integer value" do
      record.values[field] = (min || 0) + 0.5
      record.valid?
      expect(Array(record.errors[field])).not_to be_empty
    end
  end
end
