require "rails_helper"

RSpec.describe Signups::CreateService do
  def build_request(**overrides)
    SignupRequest.new({
      account_name: "Acme", name: "Jane Doe", email: "jane@example.com", password: "secret123", password_confirmation: "secret123"
    }.merge(overrides))
  end

  it "creates an account, user, default project, admin membership, and session" do
    result = described_class.new(request: build_request).call

    expect(result[:user]).to be_a(User)
    expect(result[:session]).to be_a(Session)

    user = result[:user]
    expect(user.name).to eq("Jane Doe")
    expect(user.account.name).to eq("Acme")

    project = user.account.projects_dataset.first
    expect(project.name).to eq("Default")
    expect(ProjectMembership.first(project_id: project.id, user_id: user.id).role).to eq("admin")
  end

  it "raises on fields prefixed account. for an Account-level validation failure" do
    request = build_request(account_name: "a" * 1001)

    expect { described_class.new(request: request).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: a_string_matching(/\Aaccount\./)))
    end
  end

  # Known gap: ERROR_PREFIXES only maps Account/Project/ProjectMembership, not User —
  # a User-level validation failure (e.g. this global email-uniqueness collision, which
  # SignupRequest itself can't detect) reaches ValidationError.from_model with no
  # prefix, unlike the three mapped models. Asserting the actual (plausibly deliberate,
  # since User's own field names don't collide with the other models') behavior.
  it "raises on an unprefixed field for a duplicate email (User has no ERROR_PREFIXES entry)" do
    described_class.new(request: build_request).call
    request = build_request(account_name: "Other Co", email: "jane@example.com")

    expect { described_class.new(request: request).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "email"))
    end
  end
end
