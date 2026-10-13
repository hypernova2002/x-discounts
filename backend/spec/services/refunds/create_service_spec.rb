require "rails_helper"

RSpec.describe Refunds::CreateService do
  let(:project) { create(:project) }
  let(:customer) { create(:customer, project: project) }
  let(:order) { create(:order, project: project, customer: customer) }

  it "raises ArgumentError when neither order_discount nor points_redemption is given" do
    expect { described_class.new.call }.to raise_error(ArgumentError)
  end

  it "raises ArgumentError when both order_discount and points_redemption are given" do
    order_discount = create(:order_discount, order: order, kind: "coupon", amount_off: 10)
    points_redemption = create(:points_redemption, order: order, customer: customer)
    expect { described_class.new(order_discount: order_discount, points_redemption: points_redemption).call }.to raise_error(ArgumentError)
  end

  describe "a loyalty order_discount" do
    it "claws back the full remaining points when no amount is requested" do
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 100, source: "order")
      order_discount = create(:order_discount, order: order, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)

      result = described_class.new(order_discount: order_discount, reason: "goodwill").call

      expect(result).to include(points: 100, amount_off: nil)
      entry = lot.ledger_entries_dataset.first
      expect(entry.kind).to eq("clawback")
      expect(entry.delta).to eq(-100)
      expect(entry.reason).to eq("goodwill")
    end

    it "honors a smaller explicit points amount" do
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 100, source: "order")
      order_discount = create(:order_discount, order: order, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)

      result = described_class.new(order_discount: order_discount, points: 30).call
      expect(result[:points]).to eq(30)
    end

    it "caps at what's left after a prior clawback" do
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 100, source: "order")
      order_discount = create(:order_discount, order: order, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)
      described_class.new(order_discount: order_discount, points: 80).call

      result = described_class.new(order_discount: order_discount, points: 1000).call
      expect(result[:points]).to eq(20)
    end

    it "raises on field points when nothing is left to refund" do
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 10, source: "order")
      order_discount = create(:order_discount, order: order, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)
      described_class.new(order_discount: order_discount).call

      expect { described_class.new(order_discount: order_discount).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "points"))
      end
    end

    it "raises on field base when no lot is linked" do
      order_discount = create(:order_discount, order: order, kind: "loyalty", loyalty_point_lot: nil, amount_off: nil)
      expect { described_class.new(order_discount: order_discount).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "base"))
      end
    end
  end

  describe "a plain-kind order_discount" do
    it "refunds the full remaining amount_off when nothing is requested" do
      order_discount = create(:order_discount, order: order, kind: "coupon", amount_off: 10)
      result = described_class.new(order_discount: order_discount, reason: "goodwill").call

      expect(result).to include(amount_off: 10, points: nil)
      refund = DiscountRefund.first(order_discount_id: order_discount.id)
      expect(refund.amount_off).to eq(10)
      expect(refund.reason).to eq("goodwill")
    end

    it "honors a smaller explicit amount_off" do
      order_discount = create(:order_discount, order: order, kind: "coupon", amount_off: 10)
      result = described_class.new(order_discount: order_discount, amount_off: 4).call
      expect(result[:amount_off]).to eq(4)
    end

    it "raises on field amount_off when nothing is left to refund" do
      order_discount = create(:order_discount, order: order, kind: "coupon", amount_off: 10)
      described_class.new(order_discount: order_discount).call

      expect { described_class.new(order_discount: order_discount).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "amount_off"))
      end
    end
  end

  describe "a points_redemption" do
    it "creates a new non-expiring redemption_refund lot for the full remaining points" do
      points_redemption = create(:points_redemption, order: order, customer: customer, points_redeemed: 50)

      result = described_class.new(points_redemption: points_redemption, reason: "goodwill").call

      expect(result).to include(points: 50, amount_off: nil)
      lot = customer.loyalty_point_lots_dataset.first(source: "redemption_refund")
      expect(lot.points).to eq(50)
      expect(lot.expires_at).to be_nil
      expect(lot.reason).to eq("goodwill")
    end

    it "honors a smaller explicit points amount" do
      points_redemption = create(:points_redemption, order: order, customer: customer, points_redeemed: 50)
      result = described_class.new(points_redemption: points_redemption, points: 20).call
      expect(result[:points]).to eq(20)
    end

    it "raises on field points when nothing is left to refund" do
      points_redemption = create(:points_redemption, order: order, customer: customer, points_redeemed: 10)
      described_class.new(points_redemption: points_redemption).call

      expect { described_class.new(points_redemption: points_redemption).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "points"))
      end
    end
  end
end
