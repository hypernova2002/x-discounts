require "rails_helper"

RSpec.describe ProjectMembershipResource do
  it "renders the membership's plain fields" do
    membership = create(:project_membership, role: "developer")
    hash = described_class.new(membership).to_h

    expect(hash["id"]).to eq(membership.public_id)
    expect(hash["role"]).to eq("developer")
  end

  it "omits project_id and user_id by default" do
    membership = create(:project_membership)
    hash = described_class.new(membership).to_h
    expect(hash).not_to have_key("project_id")
    expect(hash).not_to have_key("user_id")
  end

  it "includes project_id and user_id when requested" do
    membership = create(:project_membership)
    hash = described_class.new(membership, params: { includes: %w[project_id user_id] }).to_h

    expect(hash["project_id"]).to eq(membership.project.public_id)
    expect(hash["user_id"]).to eq(membership.user.public_id)
  end
end
