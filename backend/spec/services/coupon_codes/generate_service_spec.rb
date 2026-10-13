require "rails_helper"

RSpec.describe CouponCodes::GenerateService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) { create(:discount, project: project, campaign: campaign, kind: "coupon") }

  describe "mode validation" do
    it "raises on field base when none of code/count/customer_ids is given" do
      request = CouponCodeGenerateRequest.new({})
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "base"))
      end
    end

    it "raises on field base when more than one of code/count/customer_ids is given" do
      request = CouponCodeGenerateRequest.new(code: "SAVE10", count: 5)
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "base"))
      end
    end

    it "raises on field base when prefix is given alongside an exact code" do
      request = CouponCodeGenerateRequest.new(code: "SAVE10", prefix: "PROMO")
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "base"))
      end
    end

    # CouponCodeGenerateRequest's own constraint already bounds count to 1..10_000 —
    # this service's own MAX_COUNT is tighter (5000), so a count above that but still
    # within the request model's bound is what actually reaches this check.
    it "raises on field count when count exceeds the service's own MAX_COUNT" do
      request = CouponCodeGenerateRequest.new(count: described_class::MAX_COUNT + 1)
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "count"))
      end
    end
  end

  describe "manual code" do
    it "creates exactly one CouponCode with the exact given string" do
      request = CouponCodeGenerateRequest.new(code: "SAVE10")
      codes = described_class.new(discount: discount, project: project, request: request).call

      expect(codes.size).to eq(1)
      expect(codes.first.code).to eq("SAVE10")
      expect(codes.first.customer_id).to be_nil
    end

    it "binds the code to a given customer_id" do
      customer = create(:customer, project: project)
      request = CouponCodeGenerateRequest.new(code: "SAVE10", customer_id: customer.public_id)
      codes = described_class.new(discount: discount, project: project, request: request).call

      expect(codes.first.customer_id).to eq(customer.id)
    end

    it "raises on field customer_id for an unresolvable customer" do
      request = CouponCodeGenerateRequest.new(code: "SAVE10", customer_id: "cust_bogus")
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "customer_id"))
      end
    end

    it "raises on field code when the code is already in use in the project" do
      create(:coupon, discount: discount, project: project, code: "SAVE10")
      request = CouponCodeGenerateRequest.new(code: "SAVE10")

      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "code"))
      end
    end

    it "uses the request's max_redemptions" do
      request = CouponCodeGenerateRequest.new(code: "SAVE10", max_redemptions: 5)
      codes = described_class.new(discount: discount, project: project, request: request).call
      expect(codes.first.max_redemptions).to eq(5)
    end
  end

  describe "bulk anonymous (count)" do
    it "creates exactly that many unbound codes" do
      request = CouponCodeGenerateRequest.new(count: 3)
      codes = described_class.new(discount: discount, project: project, request: request).call

      expect(codes.size).to eq(3)
      expect(codes.map(&:customer_id)).to all(be_nil)
      expect(codes.map(&:code).uniq.size).to eq(3)
    end

    it "generates a bare code with neither prefix nor suffix" do
      request = CouponCodeGenerateRequest.new(count: 1)
      code = described_class.new(discount: discount, project: project, request: request).call.first
      expect(code.code).to match(/\A[A-Z0-9]{8}\z/)
    end

    it "prepends a given prefix" do
      request = CouponCodeGenerateRequest.new(count: 1, prefix: "PROMO")
      code = described_class.new(discount: discount, project: project, request: request).call.first
      expect(code.code).to match(/\APROMO-[A-Z0-9]{8}\z/)
    end

    it "appends a given suffix" do
      request = CouponCodeGenerateRequest.new(count: 1, suffix: "2026")
      code = described_class.new(discount: discount, project: project, request: request).call.first
      expect(code.code).to match(/\A[A-Z0-9]{8}-2026\z/)
    end

    it "combines a prefix and a suffix" do
      request = CouponCodeGenerateRequest.new(count: 1, prefix: "PROMO", suffix: "2026")
      code = described_class.new(discount: discount, project: project, request: request).call.first
      expect(code.code).to match(/\APROMO-[A-Z0-9]{8}-2026\z/)
    end
  end

  describe "bulk personalized (customer_ids)" do
    it "creates one customer-bound code per given id, in order" do
      c1 = create(:customer, project: project)
      c2 = create(:customer, project: project)
      request = CouponCodeGenerateRequest.new(customer_ids: [c1.public_id, c2.public_id])

      codes = described_class.new(discount: discount, project: project, request: request).call

      expect(codes.map(&:customer_id)).to eq([c1.id, c2.id])
    end

    it "raises on field customer_ids naming the offending id" do
      request = CouponCodeGenerateRequest.new(customer_ids: ["cust_bogus"])
      expect { described_class.new(discount: discount, project: project, request: request).call }.to raise_error(ValidationError) do |error|
        expect(error.details).to include(hash_including(field: "customer_ids", message: a_string_matching(/cust_bogus/)))
      end
    end
  end
end
