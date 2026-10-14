require "rails_helper"

RSpec.describe Export do
  let(:record) { create(:export) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it "rejects a missing project_id" do
    record.project_id = nil
    expect(record).not_to be_valid
  end

  it "rejects a missing export_type" do
    record.export_type = nil
    expect(record).not_to be_valid
  end

  it "rejects an export_type outside TYPES" do
    record.export_type = "bogus"
    expect(record).not_to be_valid
  end

  it "rejects a status outside STATUSES" do
    record.status = "bogus"
    expect(record).not_to be_valid
  end

  describe "#completed?" do
    it "is true when status is completed" do
      record.status = "completed"
      expect(record.completed?).to eq(true)
    end

    it "is false for any other status" do
      record.status = "pending"
      expect(record.completed?).to eq(false)
    end
  end

  describe "#file_path" do
    it "is nil when there's no filename" do
      expect(record.file_path).to be_nil
    end

    it "derives the path from the public_id and the filename's extension" do
      record.filename = "acme-campaigns-20260101.csv"
      expect(record.file_path.to_s).to end_with("storage/exports/#{record.public_id}.csv")
    end
  end
end
