require "rails_helper"

RSpec.describe ExportJob do
  let(:project) { create(:project) }

  after do
    Export.where(project: project).each do |export|
      next unless export.filename

      File.delete(export.file_path) if File.exist?(export.file_path)
    end
  end

  it "does nothing if the export no longer exists" do
    expect { described_class.new.perform(0) }.not_to raise_error
  end

  it "generates a real campaigns CSV and marks the export completed" do
    create(:campaign, project: project, name: "Spring Sale")
    export = create(:export, project: project, export_type: "campaigns")

    described_class.new.perform(export.id)
    export.refresh

    expect(export.status).to eq("completed")
    expect(export.byte_size).to be_positive
    expect(File.read(export.file_path)).to include("Spring Sale")
  end

  it "generates a real customers CSV" do
    create(:customer, project: project, external_id: "cust-1")
    export = create(:export, project: project, export_type: "customers")

    described_class.new.perform(export.id)
    export.refresh

    expect(export.status).to eq("completed")
    expect(File.read(export.file_path)).to include("cust-1")
  end

  it "generates a real orders CSV" do
    order = create(:order, project: project)
    export = create(:export, project: project, export_type: "orders")

    described_class.new.perform(export.id)
    export.refresh

    expect(export.status).to eq("completed")
    expect(File.read(export.file_path)).to include(order.public_id)
  end

  it "generates a real project zip bundling every table" do
    create(:campaign, project: project)
    export = create(:export, project: project, export_type: "project")

    described_class.new.perform(export.id)
    export.refresh

    expect(export.status).to eq("completed")
    expect(export.content_type).to eq("application/zip")
    entries = Zip::File.open(export.file_path) { |zip| zip.entries.map(&:name) }
    expect(entries).to include("campaigns.csv")
  end

  it "marks the export failed, with the error message, if generation raises" do
    export = create(:export, project: project, export_type: "campaigns")
    allow(Exports::CsvBuilder).to receive(:build).and_raise(StandardError, "boom")

    described_class.new.perform(export.id)
    export.refresh

    expect(export.status).to eq("failed")
    expect(export.error_message).to eq("boom")
  end
end
