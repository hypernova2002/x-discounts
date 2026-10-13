require "rails_helper"

RSpec.describe OtpVerifyRequest do
  let(:valid_attrs) { { otp_challenge_token: "chal_123", code: "123456" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing otp_challenge_token" do
    expect { described_class.new(valid_attrs.except(:otp_challenge_token)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty otp_challenge_token" do
    expect { described_class.new(valid_attrs.merge(otp_challenge_token: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing code" do
    expect { described_class.new(valid_attrs.except(:code)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty code" do
    expect { described_class.new(valid_attrs.merge(code: "")) }.to raise_error(Dry::Struct::Error)
  end
end
