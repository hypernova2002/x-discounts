require "rails_helper"
require "zip"
require "csv"
require "tempfile"

RSpec.describe Exports::ProjectExporter do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }

  def entry_rows(zip, entry_name)
    CSV.parse(zip.read(entry_name), headers: true)
  end

  it "writes one <table>.csv entry per TABLES key" do
    Tempfile.create(["export", ".zip"]) do |file|
      described_class.new(project: project).call(file.path)

      Zip::File.open(file.path) do |zip|
        entry_names = zip.entries.map(&:name)
        expect(entry_names).to include("campaigns.csv", "discounts.csv", "customers.csv", "orders.csv")
      end
    end
  end

  it "scopes a plain table to the project" do
    create(:campaign, project: project, name: "Mine")
    create(:campaign, project: other_project, name: "Not mine")

    Tempfile.create(["export", ".zip"]) do |file|
      described_class.new(project: project).call(file.path)

      Zip::File.open(file.path) do |zip|
        names = entry_rows(zip, "campaigns.csv").map { |r| r["name"] }
        expect(names).to contain_exactly("Mine")
      end
    end
  end

  it "resolves a foreign_keys-mapped column for a direct-foreign-key table" do
    campaign = create(:campaign, project: project)
    discount = create(:discount, project: project, campaign: campaign)

    Tempfile.create(["export", ".zip"]) do |file|
      described_class.new(project: project).call(file.path)

      Zip::File.open(file.path) do |zip|
        row = entry_rows(zip, "discounts.csv").find { |r| r["id"] == discount.public_id }
        expect(row["campaign_id"]).to eq(campaign.public_id)
      end
    end
  end

  it "scopes a subquery-based table (discount_effects) to the project's own discounts" do
    campaign = create(:campaign, project: project)
    discount = create(:discount, project: project, campaign: campaign)
    create(:discount_effect, discount: discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 10 })

    other_campaign = create(:campaign, project: other_project)
    other_discount = create(:discount, project: other_project, campaign: other_campaign)
    create(:discount_effect, discount: other_discount, effect_type: "percentage_off", scope: "cart", config: { percentage: 20 })

    Tempfile.create(["export", ".zip"]) do |file|
      described_class.new(project: project).call(file.path)

      Zip::File.open(file.path) do |zip|
        rows = entry_rows(zip, "discount_effects.csv")
        expect(rows.size).to eq(1)
        expect(rows.first["discount_id"]).to eq(discount.public_id)
      end
    end
  end
end
