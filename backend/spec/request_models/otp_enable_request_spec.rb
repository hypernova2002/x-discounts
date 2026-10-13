require "rails_helper"

RSpec.describe OtpEnableRequest do
  it "accepts a valid code" do
    expect { described_class.new(code: "123456") }.not_to raise_error
  end

  it "rejects a missing code" do
    expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty code" do
    expect { described_class.new(code: "") }.to raise_error(Dry::Struct::Error)
  end
end
