require "rails_helper"

RSpec.describe Customer do
  let(:record) { create(:customer) }

  it "is valid with sane attributes" do
    expect(record).to be_valid
  end

  it_behaves_like "a utf8-length-bounded field", :external_id, max: 255
  it_behaves_like "a utf8-length-bounded field", :email, max: 255
  it_behaves_like "a utf8-length-bounded field", :phone_number, max: 255
  it_behaves_like "a utf8-length-bounded field", :country, max: 255
  it_behaves_like "a utf8-length-bounded field", :name, max: 1000
  it_behaves_like "a boolean-typed field", :marketing_opt_in

  describe "date_of_birth" do
    it "accepts a date in the past" do
      record.date_of_birth = Date.new(1990, 1, 1)
      record.valid?
      expect(Array(record.errors[:date_of_birth])).to be_empty
    end

    it "accepts today's date" do
      record.date_of_birth = Date.today
      record.valid?
      expect(Array(record.errors[:date_of_birth])).to be_empty
    end

    it "rejects a date in the future" do
      record.date_of_birth = Date.today + 1
      record.valid?
      expect(Array(record.errors[:date_of_birth])).not_to be_empty
    end
  end

  describe "#change_membership_tier!" do
    let(:scheme) { create(:membership_scheme) }
    let(:silver) { create(:membership_tier, membership_scheme: scheme, name: "Silver") }
    let(:gold) { create(:membership_tier, membership_scheme: scheme, name: "Gold") }
    let(:customer) { create(:customer) }

    it "writes only a membership_started event on first assignment (no prior tier)" do
      customer.change_membership_tier!(silver)

      events = customer.customer_activity_events_dataset.all
      expect(events.map(&:type)).to eq(["membership_started"])
      expect(events.first.payload["tier_name"]).to eq("Silver")
    end

    it "writes both membership_ended (old tier) and membership_started (new tier) on a transition" do
      customer.change_membership_tier!(silver)

      customer.change_membership_tier!(gold)

      events = customer.customer_activity_events_dataset.order(:id).all
      expect(events.map(&:type)).to eq(%w[membership_started membership_ended membership_started])
      expect(events.last(2).map { |e| e.payload["tier_name"] }).to eq(%w[Silver Gold])
    end

    it "writes only a membership_ended event when cleared to no tier" do
      customer.change_membership_tier!(silver)

      customer.change_membership_tier!(nil)

      events = customer.customer_activity_events_dataset.order(:id).all
      expect(events.map(&:type)).to eq(%w[membership_started membership_ended])
      expect(customer.membership_tier_id).to be_nil
      expect(customer.membership_tier_entered_at).to be_nil
    end
  end
end
