require "rails_helper"
require "tempfile"

RSpec.describe Coupons::AttachDesignImageService do
  let(:project) { create(:project) }
  let(:campaign) { create(:campaign, project: project) }
  let(:discount) { create(:discount, project: project, campaign: campaign, kind: "coupon", kind_config: { valid_until: "2026-12-31T00:00:00Z" }) }

  class FakeUploadedFile
    attr_reader :content_type, :original_filename

    def initialize(content:, content_type:, original_filename:)
      @tempfile = Tempfile.new
      @tempfile.binmode
      @tempfile.write(content)
      @tempfile.rewind
      @content_type = content_type
      @original_filename = original_filename
    end

    def size
      @tempfile.size
    end

    def read
      @tempfile.read
    end
  end

  def fake_file(content: "fake image bytes", content_type: "image/png", original_filename: "mug.png")
    FakeUploadedFile.new(content: content, content_type: content_type, original_filename: original_filename)
  end

  after do
    Dir.glob(Coupons::AttachDesignImageService.storage_dir.join("#{discount.public_id}.*")).each { |path| File.delete(path) }
  end

  it "rejects a disallowed content_type" do
    file = fake_file(content_type: "application/pdf")
    expect { described_class.new(discount: discount, file: file).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "design_image"))
    end
  end

  it "rejects a file over the size limit" do
    file = fake_file(content: "x" * (described_class::MAX_BYTES + 1))
    expect { described_class.new(discount: discount, file: file).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "design_image"))
    end
  end

  it "writes the file to storage_dir named after the discount's public_id" do
    file = fake_file(original_filename: "mug.png")
    described_class.new(discount: discount, file: file).call

    path = described_class.storage_dir.join("#{discount.public_id}.png")
    expect(File.exist?(path)).to eq(true)
    expect(File.read(path)).to eq("fake image bytes")
  end

  it "merges the image metadata into kind_config, preserving unrelated existing keys" do
    file = fake_file(content: "abc", content_type: "image/png", original_filename: "mug.png")
    updated = described_class.new(discount: discount, file: file).call

    expect(updated.kind_config["design_image_filename"]).to eq("mug.png")
    expect(updated.kind_config["design_image_content_type"]).to eq("image/png")
    expect(updated.kind_config["design_image_byte_size"]).to eq(3)
    expect(updated.kind_config["valid_until"]).to eq("2026-12-31T00:00:00Z")
  end

  it "replaces a previously-attached file on re-attach" do
    described_class.new(discount: discount, file: fake_file(content: "first", original_filename: "first.png")).call
    described_class.new(discount: discount, file: fake_file(content: "second", original_filename: "second.jpeg")).call

    matches = Dir.glob(described_class.storage_dir.join("#{discount.public_id}.*"))
    expect(matches.size).to eq(1)
    expect(File.read(matches.first)).to eq("second")
  end
end
