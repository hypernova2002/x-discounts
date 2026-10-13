require "rails_helper"

RSpec.describe Discounts::StackingResolver do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }

  def candidate(discount, value)
    { discount: discount, results: [{ discount_id: discount.public_id, amount_off: value }], value: value }
  end

  it "returns an empty result for no candidates" do
    expect(described_class.resolve([])).to eq([])
  end

  it "always accepts a single candidate" do
    discount = create(:discount, project: project, campaign: campaign, stackable: false)
    result = described_class.resolve([candidate(discount, 10)])
    expect(result.map { |c| c[:discount] }).to eq([discount])
  end

  it "accepts two mutually stackable candidates with no compatibility row needed" do
    a = create(:discount, project: project, campaign: campaign, stackable: true)
    b = create(:discount, project: project, campaign: campaign, stackable: true)
    result = described_class.resolve([candidate(a, 10), candidate(b, 5)])
    expect(result.map { |c| c[:discount] }).to contain_exactly(a, b)
  end

  it "accepts only the higher-value candidate when neither is stackable and no compatibility exists" do
    low = create(:discount, project: project, campaign: campaign, stackable: false)
    high = create(:discount, project: project, campaign: campaign, stackable: false)
    result = described_class.resolve([candidate(low, 5), candidate(high, 10)])
    expect(result.map { |c| c[:discount] }).to eq([high])
  end

  it "accepts both non-stackable candidates when an explicit compatibility row exists" do
    a = create(:discount, project: project, campaign: campaign, stackable: false)
    b = create(:discount, project: project, campaign: campaign, stackable: false)
    DiscountStackingCompatibility.create(discount_id: a.id, compatible_discount_id: b.id)

    result = described_class.resolve([candidate(a, 10), candidate(b, 5)])
    expect(result.map { |c| c[:discount] }).to contain_exactly(a, b)
  end

  it "honors a one-directional compatibility row regardless of evaluation order" do
    a = create(:discount, project: project, campaign: campaign, stackable: false)
    b = create(:discount, project: project, campaign: campaign, stackable: false)
    DiscountStackingCompatibility.create(discount_id: b.id, compatible_discount_id: a.id)

    result = described_class.resolve([candidate(a, 10), candidate(b, 5)])
    expect(result.map { |c| c[:discount] }).to contain_exactly(a, b)
  end

  it "excludes a candidate incompatible with any already-accepted candidate, not just the most recent" do
    a = create(:discount, project: project, campaign: campaign, stackable: true)
    b = create(:discount, project: project, campaign: campaign, stackable: true)
    c = create(:discount, project: project, campaign: campaign, stackable: false)

    result = described_class.resolve([candidate(a, 30), candidate(b, 20), candidate(c, 10)])
    expect(result.map { |c| c[:discount] }).to eq([a, b])
  end

  it "returns accepted candidates in descending value order" do
    a = create(:discount, project: project, campaign: campaign, stackable: true)
    b = create(:discount, project: project, campaign: campaign, stackable: true)
    result = described_class.resolve([candidate(a, 5), candidate(b, 20)])
    expect(result.map { |c| c[:value] }).to eq([20, 5])
  end
end
