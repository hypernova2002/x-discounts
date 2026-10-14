require "rails_helper"

RSpec.describe DiscountStackingCompatibility do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:a) { create(:discount, project: project, campaign: campaign) }
  let(:b) { create(:discount, project: project, campaign: campaign) }

  it "is valid with sane attributes" do
    record = described_class.new(discount_id: a.id, compatible_discount_id: b.id)
    expect(record).to be_valid
  end

  it "rejects a missing discount_id" do
    record = described_class.new(compatible_discount_id: b.id)
    expect(record).not_to be_valid
  end

  it "rejects a missing compatible_discount_id" do
    record = described_class.new(discount_id: a.id)
    expect(record).not_to be_valid
  end

  # DiscountStackingCompatibilities::CreateService already guards this before ever
  # constructing the model — this confirms the model enforces it independently too,
  # as a second layer, not just relying on that one call site to check first.
  it "rejects compatible_discount_id equal to discount_id" do
    record = described_class.new(discount_id: a.id, compatible_discount_id: a.id)
    expect(record).not_to be_valid
    expect(record.errors[:compatible_discount_id]).to include("cannot equal discount_id")
  end

  describe "#audit_project_id" do
    it "delegates to the discount's project_id" do
      record = described_class.create(discount_id: a.id, compatible_discount_id: b.id)
      expect(record.audit_project_id).to eq(a.project_id)
    end
  end

  describe "#audit_label" do
    it "names both discounts" do
      discount_a = create(:discount, project: project, campaign: campaign, name: "10% Off")
      discount_b = create(:discount, project: project, campaign: campaign, name: "Free Shipping")
      record = described_class.create(discount_id: discount_a.id, compatible_discount_id: discount_b.id)

      expect(record.audit_label).to eq("Stacking compatibility: 10% Off ↔ Free Shipping")
    end
  end
end
