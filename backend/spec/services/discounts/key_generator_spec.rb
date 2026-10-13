require "rails_helper"

RSpec.describe Discounts::KeyGenerator do
  let(:project) { create(:project) }

  it "slugifies a name: lowercase, spaces to hyphens" do
    expect(described_class.generate(name: "Summer Sale", project: project)).to eq("summer-sale")
  end

  it "collapses runs of non-alphanumeric characters into a single hyphen" do
    expect(described_class.generate(name: "Summer Sale!! 2026", project: project)).to eq("summer-sale-2026")
  end

  it "strips leading and trailing hyphens" do
    expect(described_class.generate(name: "  !!Sale!!  ", project: project)).to eq("sale")
  end

  it "falls back to 'discount' when the name has no alphanumeric characters" do
    expect(described_class.generate(name: "!!!", project: project)).to eq("discount")
  end

  it "falls back to 'discount' for a blank name" do
    expect(described_class.generate(name: "", project: project)).to eq("discount")
  end

  it "appends -2 when the base key already exists in the project" do
    create(:discount, project: project, key: "sale")
    expect(described_class.generate(name: "Sale", project: project)).to eq("sale-2")
  end

  it "appends -3 when both the base key and -2 already exist" do
    create(:discount, project: project, key: "sale")
    create(:discount, project: project, key: "sale-2")
    expect(described_class.generate(name: "Sale", project: project)).to eq("sale-3")
  end

  it "doesn't collide across different projects" do
    other_project = create(:project)
    create(:discount, project: other_project, key: "sale")
    expect(described_class.generate(name: "Sale", project: project)).to eq("sale")
  end
end
