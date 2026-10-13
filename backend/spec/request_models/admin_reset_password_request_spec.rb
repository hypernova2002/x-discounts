require "rails_helper"

RSpec.describe AdminResetPasswordRequest do
  let(:valid_attrs) { { password: "newpassword123", password_confirmation: "newpassword123" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  it "rejects a missing password" do
    expect { described_class.new(valid_attrs.except(:password)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty password" do
    expect { described_class.new(valid_attrs.merge(password: "")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing password_confirmation" do
    expect { described_class.new(valid_attrs.except(:password_confirmation)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty password_confirmation" do
    expect { described_class.new(valid_attrs.merge(password_confirmation: "")) }.to raise_error(Dry::Struct::Error)
  end
end
