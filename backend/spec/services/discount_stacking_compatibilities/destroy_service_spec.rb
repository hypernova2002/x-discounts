require "rails_helper"

RSpec.describe DiscountStackingCompatibilities::DestroyService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:a) { create(:discount, project: project, campaign: campaign) }
  let(:b) { create(:discount, project: project, campaign: campaign) }

  it "deletes both directional rows" do
    DiscountStackingCompatibilities::CreateService.new(discount: a, compatible_discount: b).call

    described_class.new(discount: a, compatible_discount: b).call

    expect(DiscountStackingCompatibility.where(discount_id: a.id, compatible_discount_id: b.id)).to be_empty
    expect(DiscountStackingCompatibility.where(discount_id: b.id, compatible_discount_id: a.id)).to be_empty
  end

  it "doesn't raise when no rows exist" do
    expect { described_class.new(discount: a, compatible_discount: b).call }.not_to raise_error
  end
end
