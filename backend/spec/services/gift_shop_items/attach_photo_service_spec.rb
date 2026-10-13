require "rails_helper"
require "tempfile"

RSpec.describe GiftShopItems::AttachPhotoService do
  let(:project) { create(:project) }
  let(:item) { create(:gift_shop_item, project: project) }

  class FakeUploadedPhoto
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

  def fake_file(content: "fake image bytes", content_type: "image/png", original_filename: "item.png")
    FakeUploadedPhoto.new(content: content, content_type: content_type, original_filename: original_filename)
  end

  after do
    Dir.glob(GiftShopItems::AttachPhotoService.storage_dir.join("#{item.public_id}.*")).each { |path| File.delete(path) }
  end

  it "rejects a disallowed content_type" do
    expect { described_class.new(item: item, file: fake_file(content_type: "application/pdf")).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "photo"))
    end
  end

  it "rejects a file over the size limit" do
    file = fake_file(content: "x" * (described_class::MAX_BYTES + 1))
    expect { described_class.new(item: item, file: file).call }.to raise_error(ValidationError) do |error|
      expect(error.details).to include(hash_including(field: "photo"))
    end
  end

  it "writes the file to storage_dir named after the item's public_id" do
    described_class.new(item: item, file: fake_file(original_filename: "item.png")).call
    path = described_class.storage_dir.join("#{item.public_id}.png")
    expect(File.exist?(path)).to eq(true)
  end

  it "updates the item's photo columns" do
    updated = described_class.new(item: item, file: fake_file(content: "abc", content_type: "image/png", original_filename: "item.png")).call

    expect(updated.photo_filename).to eq("item.png")
    expect(updated.photo_content_type).to eq("image/png")
    expect(updated.photo_byte_size).to eq(3)
  end

  it "replaces a previously-attached photo on re-attach" do
    described_class.new(item: item, file: fake_file(content: "first", original_filename: "first.png")).call
    described_class.new(item: item, file: fake_file(content: "second", original_filename: "second.png")).call

    matches = Dir.glob(described_class.storage_dir.join("#{item.public_id}.*"))
    expect(matches.size).to eq(1)
    expect(File.read(matches.first)).to eq("second")
  end
end
