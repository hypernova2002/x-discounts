require "rails_helper"

RSpec.describe CustomAttributeRequest do
  let(:valid_attrs) { { entity: "customer", key: "loyalty_tier", data_type: "string" } }

  it "accepts valid attributes" do
    expect { described_class.new(valid_attrs) }.not_to raise_error
  end

  ConditionVocabulary::ENTITIES.each do |entity|
    it "accepts the #{entity} entity" do
      expect { described_class.new(valid_attrs.merge(entity: entity)) }.not_to raise_error
    end
  end

  it "rejects an entity outside ConditionVocabulary::ENTITIES" do
    expect { described_class.new(valid_attrs.merge(entity: "invoice")) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects a missing key" do
    expect { described_class.new(valid_attrs.except(:key)) }.to raise_error(Dry::Struct::Error)
  end

  it "rejects an empty key" do
    expect { described_class.new(valid_attrs.merge(key: "")) }.to raise_error(Dry::Struct::Error)
  end

  ConditionVocabulary::DATA_TYPES.each do |data_type|
    it "accepts the #{data_type} data_type" do
      expect { described_class.new(valid_attrs.merge(data_type: data_type)) }.not_to raise_error
    end
  end

  it "rejects a data_type outside ConditionVocabulary::DATA_TYPES" do
    expect { described_class.new(valid_attrs.merge(data_type: "array")) }.to raise_error(Dry::Struct::Error)
  end
end
