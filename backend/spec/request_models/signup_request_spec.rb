require "rails_helper"

RSpec.describe SignupRequest do
  let(:valid_attrs) do
    { account_name: "Acme", name: "Jane Doe", email: "jane@example.com", password: "secret123", password_confirmation: "secret123" }
  end

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  %i[account_name name email password password_confirmation].each do |field|
    it "rejects a missing #{field}" do
      expect { described_class.new(valid_attrs.except(field)) }.to raise_error(Dry::Struct::Error)
    end

    it "rejects an empty #{field}" do
      expect { described_class.new(valid_attrs.merge(field => "")) }.to raise_error(Dry::Struct::Error)
    end
  end
end
