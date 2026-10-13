require "rails_helper"

RSpec.describe Projects::CreateService do
  let(:account) { create(:account) }
  let(:creator) { create(:user, account: account) }

  it "creates a project owned by the account" do
    request = ProjectRequest.new(name: "New Project")
    project = described_class.new(account: account, creator: creator, request: request).call

    expect(project.name).to eq("New Project")
    expect(project.account_id).to eq(account.id)
  end

  it "adds the creator as an admin project membership" do
    request = ProjectRequest.new(name: "New Project")
    project = described_class.new(account: account, creator: creator, request: request).call

    membership = ProjectMembership.first(project_id: project.id, user_id: creator.id)
    expect(membership.role).to eq("admin")
  end

  it "applies an explicit timezone and currency" do
    request = ProjectRequest.new(name: "New Project", timezone: "America/New_York", currency: "EUR")
    project = described_class.new(account: account, creator: creator, request: request).call

    expect(project.timezone).to eq("America/New_York")
    expect(project.currency).to eq("EUR")
  end

  it "leaves timezone and currency at the model's own default when omitted" do
    default_project = create(:project)
    request = ProjectRequest.new(name: "New Project")

    project = described_class.new(account: account, creator: creator, request: request).call

    expect(project.timezone).to eq(default_project.timezone)
    expect(project.currency).to eq(default_project.currency)
  end

  it "raises a ValidationError for a name over the model's length bound" do
    request = ProjectRequest.new(name: "a" * 1001)
    expect { described_class.new(account: account, creator: creator, request: request).call }.to raise_error(ValidationError)
  end
end
