require "rails_helper"
require "csv"

RSpec.describe Exports::CsvBuilder do
  include QueryCounter

  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def rows_for(io_content)
    CSV.parse(io_content, headers: true)
  end

  it "drops id and project_id by default, renaming public_id to id" do
    create(:campaign, project: project, name: "Summer Sale")
    io = StringIO.new
    described_class.build(io, project.campaigns_dataset)

    parsed = rows_for(io.string)
    expect(parsed.headers).to include("id")
    expect(parsed.headers).not_to include("project_id")
    expect(parsed.first["id"]).to eq(campaign.project.campaigns_dataset.first.public_id)
  end

  it "resolves a foreign_keys-mapped column to the referenced row's public_id" do
    discount = create(:discount, project: project, campaign: campaign)
    io = StringIO.new
    described_class.build(io, project.discounts_dataset, foreign_keys: { campaign_id: Campaign })

    parsed = rows_for(io.string)
    expect(parsed.first["campaign_id"]).to eq(campaign.public_id)
    expect(parsed.first["campaign_id"]).not_to eq(discount.campaign_id.to_s)
  end

  it "resolves a nil foreign-key value to nil, not an error" do
    create(:coupon, discount: create(:discount, project: project, campaign: campaign, kind: "coupon"), project: project, customer: nil)
    io = StringIO.new
    described_class.build(io, CouponCode.where(project_id: project.id), foreign_keys: { customer_id: Customer })

    parsed = rows_for(io.string)
    expect(parsed.first["customer_id"]).to be_nil
  end

  it "caches foreign-key resolution across rows sharing the same referenced id" do
    3.times { create(:discount, project: project, campaign: campaign) }
    io = StringIO.new

    query_count = count_queries { described_class.build(io, project.discounts_dataset, foreign_keys: { campaign_id: Campaign }) }

    # One query to stream discounts, one to resolve the shared campaign_id the first
    # time it's seen — a third query here would mean the cache isn't working.
    expect(query_count).to eq(2)
  end

  it "serializes a Time/DateTime value as ISO8601" do
    order = create(:order, project: project, created_at: Time.utc(2026, 6, 1, 12, 0, 0))
    io = StringIO.new
    described_class.build(io, project.orders_dataset.where(id: order.id))

    parsed = rows_for(io.string)
    expect(parsed.first["created_at"]).to eq("2026-06-01T12:00:00Z")
  end

  it "serializes a hash-like (jsonb) value as a JSON string" do
    discount = create(:discount, project: project, campaign: campaign, kind_config: { active_from: "2026-01-01T00:00:00Z" })
    io = StringIO.new
    described_class.build(io, project.discounts_dataset.where(id: discount.id))

    parsed = rows_for(io.string)
    expect(JSON.parse(parsed.first["kind_config"])).to eq({ "active_from" => "2026-01-01T00:00:00Z" })
  end
end
