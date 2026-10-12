require "rails_helper"

RSpec.describe Campaign do
  let(:record) { create(:campaign) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :enabled
  it_behaves_like "a boolean-typed field", :archived

  describe "#discount_summary" do
    it "nets total amount_off against total refunded amount, and excludes a fully-refunded row's redemption from the count" do
      campaign = create(:campaign)
      discount = create(:discount, campaign: campaign, kind: "promotion")

      create(:order_discount, discount: discount, kind: "promotion", amount_off: 20)

      partially_refunded = create(:order_discount, discount: discount, kind: "promotion", amount_off: 30)
      create(:discount_refund, order_discount: partially_refunded, amount_off: 10)

      summary = campaign.discount_summary

      expect(summary[:count]).to eq(1)
      # redemption_count excludes any row with a refund at all (same as
      # OrderDiscount#refunded?/excluding_refunded), partial or full — only
      # the untouched row counts.
      expect(summary[:redemption_count]).to eq(1)
      # discounted_amount instead nets the actual refunded currency across
      # every row, partial refunds included: 20 + 30 - 10 = 40.
      expect(summary[:discounted_amount]).to eq(40)
    end
  end
end
