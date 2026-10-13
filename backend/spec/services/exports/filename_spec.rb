require "rails_helper"

RSpec.describe Exports::Filename do
  let(:today) { Time.now.utc.strftime("%Y%m%d") }

  it "joins parts with hyphens and appends today's date and the extension" do
    expect(described_class.build("acme", "campaigns", ext: "csv")).to eq("acme-campaigns-#{today}.csv")
  end

  it "slugifies parts with special characters" do
    expect(described_class.build("Acme Inc.", ext: "zip")).to eq("acme-inc-#{today}.zip")
  end

  it "collapses runs of non-alphanumeric characters into a single hyphen" do
    expect(described_class.build("Acme & Co!!", ext: "csv")).to eq("acme-co-#{today}.csv")
  end
end
