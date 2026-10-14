require "rails_helper"

RSpec.describe ProjectMembership do
  let(:record) { create(:project_membership) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it "rejects a missing project_id" do
    record.project_id = nil
    expect(record).not_to be_valid
  end

  it "rejects a missing user_id" do
    record.user_id = nil
    expect(record).not_to be_valid
  end

  ProjectMembership::ROLES.each do |role|
    it "accepts the #{role} role" do
      record.role = role
      expect(record).to be_valid
    end
  end

  it "rejects a role outside ROLES" do
    record.role = "owner"
    expect(record).not_to be_valid
  end

  it "rejects a (project_id, user_id) pair that's already a member" do
    duplicate = ProjectMembership.new(project: record.project, user: record.user, role: "viewer")
    expect(duplicate).not_to be_valid
  end

  it "allows the same user to belong to a different project" do
    other_project = create(:project)
    duplicate = ProjectMembership.new(project: other_project, user: record.user, role: "viewer")
    expect(duplicate).to be_valid
  end

  describe "#audit_label" do
    it "combines the user's email and role" do
      expect(record.audit_label).to eq("#{record.user.email} (#{record.role})")
    end
  end
end
