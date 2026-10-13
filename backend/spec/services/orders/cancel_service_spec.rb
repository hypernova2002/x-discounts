require "rails_helper"

RSpec.describe Orders::CancelService do
  let(:project) { create(:project) }
  let(:customer) { create(:customer, project: project) }
  let(:order) { create(:order, project: project, customer: customer) }

  it "stamps cancelled_at" do
    described_class.new(order: order).call
    expect(order.reload.cancelled_at).not_to be_nil
  end

  it "raises on field base when the order is already cancelled" do
    described_class.new(order: order).call
    expect { described_class.new(order: order).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "base"))
    end
  end

  it "creates no refund rows when refund: isn't requested" do
    discount = create(:discount, project: project)
    create(:order_discount, order: order, discount: discount, kind: "coupon", amount_off: 10)

    described_class.new(order: order, refund: false).call

    expect(DiscountRefund.count).to eq(0)
  end

  describe "with refund: true" do
    it "refunds a refundable plain-discount line" do
      discount = create(:discount, project: project, refundable: true)
      order_discount = create(:order_discount, order: order, discount: discount, kind: "coupon", amount_off: 10)

      described_class.new(order: order, refund: true, reason: "cancelled").call

      refund = DiscountRefund.first(order_discount_id: order_discount.id)
      expect(refund).not_to be_nil
      expect(refund.amount_off).to eq(10)
      expect(refund.reason).to eq("cancelled")
    end

    it "does not refund a non-refundable discount's line" do
      discount = create(:discount, project: project, refundable: false)
      order_discount = create(:order_discount, order: order, discount: discount, kind: "coupon", amount_off: 10)

      described_class.new(order: order, refund: true).call

      expect(DiscountRefund.first(order_discount_id: order_discount.id)).to be_nil
    end

    it "refunds a refundable loyalty line via a clawback" do
      discount = create(:discount, project: project, refundable: true)
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 50, source: "order")
      create(:order_discount, order: order, discount: discount, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)

      described_class.new(order: order, refund: true).call

      expect(lot.ledger_entries_dataset.first(kind: "clawback")).not_to be_nil
    end

    it "skips a loyalty line that's already been fully clawed back" do
      discount = create(:discount, project: project, refundable: true)
      lot = create(:loyalty_point_lot, customer: customer, order: order, points: 50, source: "order")
      order_discount = create(:order_discount, order: order, discount: discount, kind: "loyalty", loyalty_point_lot: lot, amount_off: nil)
      Refunds::CreateService.new(order_discount: order_discount).call

      expect { described_class.new(order: order, refund: true).call }.not_to raise_error
    end

    it "skips a plain-discount line that's already been fully refunded" do
      discount = create(:discount, project: project, refundable: true)
      order_discount = create(:order_discount, order: order, discount: discount, kind: "coupon", amount_off: 10)
      Refunds::CreateService.new(order_discount: order_discount).call

      expect { described_class.new(order: order, refund: true).call }.not_to raise_error
      expect(DiscountRefund.where(order_discount_id: order_discount.id).count).to eq(1)
    end

    it "refunds the order's points_redemption when it has remaining refundable points" do
      create(:points_redemption, order: order, customer: customer, points_redeemed: 20)

      described_class.new(order: order, refund: true).call

      expect(customer.loyalty_point_lots_dataset.first(source: "redemption_refund")).not_to be_nil
    end

    it "doesn't block cancellation or other lines when one refund fails" do
      discount = create(:discount, project: project, refundable: true)
      # A loyalty order_discount with no linked lot can never be refunded (Refunds::CreateService
      # raises "no linked points lot found") — confirms this failure is swallowed, not propagated.
      create(:order_discount, order: order, discount: discount, kind: "loyalty", loyalty_point_lot: nil, amount_off: nil)
      good_discount = create(:discount, project: project, refundable: true)
      good_order_discount = create(:order_discount, order: order, discount: good_discount, kind: "coupon", amount_off: 5)

      described_class.new(order: order, refund: true).call

      expect(order.reload.cancelled_at).not_to be_nil
      expect(DiscountRefund.first(order_discount_id: good_order_discount.id)).not_to be_nil
    end
  end
end
