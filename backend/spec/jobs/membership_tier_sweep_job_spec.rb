# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembershipTierSweepJob do
  describe "#perform" do
    it "evaluates every customer across every project when no project_id is given" do
      project_a = create(:project)
      project_b = create(:project)
      customers = [create(:customer, project: project_a), create(:customer, project: project_a), create(:customer, project: project_b)]

      evaluated = []
      allow(Memberships::EvaluateCustomerService).to receive(:new) do |customer:|
        evaluated << customer.id
        instance_double(Memberships::EvaluateCustomerService, call: customer)
      end

      described_class.new.perform

      expect(evaluated).to match_array(customers.map(&:id))
    end

    it "scopes to just one project's customers when project_id is given" do
      project_a = create(:project)
      project_b = create(:project)
      customer_a = create(:customer, project: project_a)
      create(:customer, project: project_b)

      evaluated = []
      allow(Memberships::EvaluateCustomerService).to receive(:new) do |customer:|
        evaluated << customer.id
        instance_double(Memberships::EvaluateCustomerService, call: customer)
      end

      described_class.new.perform(project_id: project_a.id)

      expect(evaluated).to eq([customer_a.id])
    end
  end
end
