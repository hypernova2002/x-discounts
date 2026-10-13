require "rails_helper"

RSpec.describe ApiKeyRequest do
  let(:valid_attrs) { { user_id: "usr_123", role: "admin", name: "CI key" } }

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
    expect { described_class.new(valid_attrs.merge(role: "superadmin")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(valid_attrs.merge(name: "")) }.to raise_error(Dry::Struct::Error)
  end
end
