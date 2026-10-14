require "rails_helper"

RSpec.describe CustomerActivityEvent do
  let(:customer) { create(:customer) }

  describe ".record!" do
    it "derives project_id from the given customer" do
      event = described_class.record!(customer: customer, type: "order", occurred_at: Time.now.utc)
      expect(event.project_id).to eq(customer.project_id)
      expect(event.customer_id).to eq(customer.id)
    end

    it "defaults payload to an empty hash" do
      event = described_class.record!(customer: customer, type: "order", occurred_at: Time.now.utc)
      expect(event.payload.to_h).to eq({})
    end

    it "stores a given payload" do
      event = described_class.record!(customer: customer, type: "gift_shop_redemption", occurred_at: Time.now.utc,
                                        payload: { item_name: "Mug", quantity: 1 })
      expect(event.payload.to_h).to eq({ "item_name" => "Mug", "quantity" => 1 })
    end
  end

  describe "validations" do
    let(:record) { described_class.new(customer_id: customer.id, project_id: customer.project_id, type: "order", occurred_at: Time.now.utc) }

    it "is valid with sane attributes" do
      expect(record).to be_valid
    end

    it "rejects a missing customer_id" do
      record.customer_id = nil
      expect(record).not_to be_valid
    end

    it "rejects a missing project_id" do
      record.project_id = nil
      expect(record).not_to be_valid
    end

    it "rejects a missing occurred_at" do
      record.occurred_at = nil
      expect(record).not_to be_valid
    end

    CustomerActivityEvent::TYPES.each do |type|
      it "accepts the #{type} type" do
        record.type = type
        expect(record).to be_valid
      end
    end

    it "rejects a type outside TYPES" do
      record.type = "bogus"
      expect(record).not_to be_valid
    end
  end
end
