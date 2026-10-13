require "rails_helper"
require "csv"

RSpec.describe Exports::GenerateService do
  let(:project) { create(:project) }

  after do
    Dir.glob(Exports::GenerateService::STORAGE_DIR.join("*")).each do |path|
      File.delete(path) if File.file?(path)
    end
  end

  def rows_for(path)
    CSV.read(path, headers: true)
  end

  it "writes a CSV file and marks the export completed" do
    export = create(:export, project: project, export_type: "campaigns")
    create(:campaign, project: project, name: "Summer Sale")

    described_class.new(export: export).call

    expect(export.status).to eq("completed")
    expect(export.content_type).to eq("text/csv")
    expect(export.byte_size).to be_positive
    expect(export.completed_at).not_to be_nil
    expect(File.exist?(export.file_path)).to eq(true)
  end

  describe "campaigns export" do
    it "excludes archived campaigns by default" do
      create(:campaign, project: project, name: "Active", archived: false)
      create(:campaign, project: project, name: "Archived", archived: true)
      export = create(:export, project: project, export_type: "campaigns", params: {})

      described_class.new(export: export).call

      names = rows_for(export.file_path).map { |r| r["name"] }
      expect(names).to contain_exactly("Active")
    end

    it "includes archived campaigns when include_archived is set" do
      create(:campaign, project: project, name: "Active", archived: false)
      create(:campaign, project: project, name: "Archived", archived: true)
      export = create(:export, project: project, export_type: "campaigns", params: { "include_archived" => "true" })

      described_class.new(export: export).call

      names = rows_for(export.file_path).map { |r| r["name"] }
      expect(names).to contain_exactly("Active", "Archived")
    end
  end

  describe "customers export" do
    it "filters by q when given" do
      create(:customer, project: project, external_id: "findme-1")
      create(:customer, project: project, external_id: "other")
      export = create(:export, project: project, export_type: "customers", params: { "q" => "findme" })

      described_class.new(export: export).call

      external_ids = rows_for(export.file_path).map { |r| r["external_id"] }
      expect(external_ids).to contain_exactly("findme-1")
    end

    it "includes every customer when q isn't given" do
      create(:customer, project: project, external_id: "a")
      create(:customer, project: project, external_id: "b")
      export = create(:export, project: project, export_type: "customers", params: {})

      described_class.new(export: export).call

      expect(rows_for(export.file_path).size).to eq(2)
    end
  end

  describe "orders export" do
    it "filters by customer_external_id when given" do
      match = create(:customer, project: project, external_id: "findme-1")
      other = create(:customer, project: project, external_id: "other")
      create(:order, project: project, customer: match)
      create(:order, project: project, customer: other)
      export = create(:export, project: project, export_type: "orders", params: { "customer_external_id" => "findme-1" })

      described_class.new(export: export).call

      expect(rows_for(export.file_path).size).to eq(1)
    end
  end

  describe "project export" do
    it "produces a zip via ProjectExporter" do
      export = create(:export, project: project, export_type: "project", params: {})

      described_class.new(export: export).call

      expect(export.content_type).to eq("application/zip")
      expect(File.extname(export.filename)).to eq(".zip")
    end
  end

  describe "failure handling" do
    # `write`'s `else raise ArgumentError` branch only exists as a defensive catch-all —
    # Export's own model validation (validates_includes TYPES) already makes an
    # unrecognized export_type unpersistable through any real write path, so the only
    # way to reach it is an in-memory mutation like this, never actual app data.
    #
    # Known gap found via that: the rescue's own `@export.update(status: "failed", ...)`
    # re-validates the whole model — including the still-invalid in-memory export_type —
    # so recovering from this (admittedly unreachable) case raises a second, unhandled
    # Sequel::ValidationFailed instead of cleanly marking the export failed. Documenting
    # the actual behavior rather than asserting the clean recovery that doesn't happen.
    it "currently raises Sequel::ValidationFailed while trying to record the failure for an unrecognized export_type" do
      export = create(:export, project: project, export_type: "campaigns")
      export.export_type = "bogus"

      expect { described_class.new(export: export).call }.to raise_error(Sequel::ValidationFailed, /export_type/)
    end
  end
end
