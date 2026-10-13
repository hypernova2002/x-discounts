require "rails_helper"

RSpec.describe OtpDisableRequest do
  it "accepts a valid current_password" do
    expect { described_class.new(current_password: "secret123") }.not_to raise_error
  end

  it "rejects a missing current_password" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty current_password" do
    expect { described_class.new(current_password: "") }.to raise_error(Dry::Struct::Error)
  end
end
