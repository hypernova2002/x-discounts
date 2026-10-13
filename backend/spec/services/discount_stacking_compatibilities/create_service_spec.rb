require "rails_helper"

RSpec.describe DiscountStackingCompatibilities::CreateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:a) { create(:discount, project: project, campaign: campaign) }
  let(:b) { create(:discount, project: project, campaign: campaign) }

  it "raises on field compatible_discount_id when paired with itself" do
    expect { described_class.new(discount: a, compatible_discount: a).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "compatible_discount_id"))
    end
  end

  it "creates both directional rows" do
    described_class.new(discount: a, compatible_discount: b).call

    expect(DiscountStackingCompatibility.where(discount_id: a.id, compatible_discount_id: b.id)).not_to be_empty
    expect(DiscountStackingCompatibility.where(discount_id: b.id, compatible_discount_id: a.id)).not_to be_empty
  end

  it "doesn't create duplicate rows when called again" do
    described_class.new(discount: a, compatible_discount: b).call
    described_class.new(discount: a, compatible_discount: b).call

    expect(DiscountStackingCompatibility.where(discount_id: a.id, compatible_discount_id: b.id).count).to eq(1)
  end
end
