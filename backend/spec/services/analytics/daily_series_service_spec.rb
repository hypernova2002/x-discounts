require "rails_helper"

RSpec.describe Analytics::DailySeriesService do
  let(:project) { create(:project) }
  let(:from) { Date.new(2026, 6, 1) }
  let(:to) { Date.new(2026, 6, 3) }
  let(:service) { described_class.new(from: from, to: to) }

  describe "#series" do
    it "zero-fills every day in range with no matching rows" do
      result = service.series(project.orders_dataset)
      expect(result).to eq([
                              { date: "2026-06-01", value: 0.0 },
                              { date: "2026-06-02", value: 0.0 },
                              { date: "2026-06-03", value: 0.0 }
                            ])
    end

    it "counts rows per day by default" do
      create(:order, project: project, created_at: Time.utc(2026, 6, 1, 10, 0, 0))
      create(:order, project: project, created_at: Time.utc(2026, 6, 1, 14, 0, 0))
      create(:order, project: project, created_at: Time.utc(2026, 6, 2, 9, 0, 0))

      result = service.series(project.orders_dataset)
      expect(result).to eq([
                              { date: "2026-06-01", value: 2.0 },
                              { date: "2026-06-02", value: 1.0 },
                              { date: "2026-06-03", value: 0.0 }
                            ])
    end

    it "sums the given value column per day when provided" do
      create(:order, project: project, total_amount: 10, created_at: Time.utc(2026, 6, 1))
      create(:order, project: project, total_amount: 25, created_at: Time.utc(2026, 6, 1))

      result = service.series(project.orders_dataset, value: :total_amount)
      expect(result.first).to eq({ date: "2026-06-01", value: 35.0 })
    end

    it "always returns a Float, never a BigDecimal or nil" do
      create(:order, project: project, total_amount: 10, created_at: Time.utc(2026, 6, 1))
      result = service.series(project.orders_dataset, value: :total_amount)
      expect(result.first[:value]).to be_a(Float)
      expect(result.last[:value]).to be_a(Float)
    end
  end

  describe "#total" do
    it "sums the given value column across the whole dataset" do
      create(:order, project: project, total_amount: 10, created_at: Time.utc(2026, 6, 1))
      create(:order, project: project, total_amount: 25, created_at: Time.utc(2026, 6, 2))

      expect(service.total(project.orders_dataset, value: :total_amount)).to eq(35.0)
    end

    it "returns 0.0, not nil, for an empty dataset" do
      expect(service.total(project.orders_dataset, value: :total_amount)).to eq(0.0)
    end

    it "counts rows by default" do
      create(:order, project: project, created_at: Time.utc(2026, 6, 1))
      create(:order, project: project, created_at: Time.utc(2026, 6, 2))

      expect(service.total(project.orders_dataset)).to eq(2.0)
    end
  end
end
