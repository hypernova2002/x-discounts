require "rails_helper"

RSpec.describe ProjectMembershipRequest do
  let(:valid_attrs) { { user_id: "usr_123", role: "developer" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing user_id" do
    expect { described_class.new(valid_attrs.except(:user_id)) }.to raise_error(Dry::Struct::Error)
  end

  ProjectMembership::ROLES.each do |role|
    it "accepts the #{role} role" do
      expect { described_class.new(valid_attrs.merge(role: role)) }.not_to raise_error
    end
  end

  it "rejects a role outside ProjectMembership::ROLES" do
    expect { described_class.new(valid_attrs.merge(role: "owner")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing role" do
    expect { described_class.new(valid_attrs.except(:role)) }.to raise_error(Dry::Struct::Error)
  end
end
