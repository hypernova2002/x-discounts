require "rails_helper"

RSpec.describe UserRequest do
  let(:valid_attrs) { { name: "Jane Doe", email: "jane@example.com" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing name" do
    expect { described_class.new(valid_attrs.except(:name)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty name" do
    expect { described_class.new(valid_attrs.merge(name: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing email" do
    expect { described_class.new(valid_attrs.except(:email)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty email" do
    expect { described_class.new(valid_attrs.merge(email: "")) }.to raise_error(Dry::Struct::Error)
  end
end
