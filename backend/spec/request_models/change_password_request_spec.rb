require "rails_helper"

RSpec.describe ChangePasswordRequest do
  let(:valid_attrs) { { current_password: "oldpass123", new_password: "newpass123", new_password_confirmation: "newpass123" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  %i[current_password new_password new_password_confirmation].each do |field|
    it "rejects a missing #{field}" do
      expect { described_class.new(valid_attrs.except(field)) }.to raise_error(Dry::Struct::Error)
    end

    it "rejects an empty #{field}" do
      expect { described_class.new(valid_attrs.merge(field => "")) }.to raise_error(Dry::Struct::Error)
    end
  end
end
