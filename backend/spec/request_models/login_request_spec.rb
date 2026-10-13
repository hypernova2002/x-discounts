require "rails_helper"

RSpec.describe LoginRequest do
  let(:valid_attrs) { { email: "jane@example.com", password: "secret123" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing email" do
    expect { described_class.new(valid_attrs.except(:email)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty email" do
    expect { described_class.new(valid_attrs.merge(email: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing password" do
    expect { described_class.new(valid_attrs.except(:password)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty password" do
    expect { described_class.new(valid_attrs.merge(password: "")) }.to raise_error(Dry::Struct::Error)
  end
end
