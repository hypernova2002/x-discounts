# frozen_string_literal: true

module GiftShopItems
  # Bespoke local-disk photo storage — this app is Sequel-only with no ActiveRecord,
  # and ActiveStorage hard-depends on ActiveRecord, so this avoids pulling in a
  # second ORM just to store a handful of admin-uploaded product photos. Files live
  # under storage/gift_shop_items/<public_id><ext>, named by the item's own opaque
  # id so nothing ever collides and nothing needs a lookup table.
  class AttachPhotoService
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    MAX_BYTES = 5.megabytes

    def self.storage_dir
      Rails.root.join("storage", "gift_shop_items")
    end

    def initialize(item:, file:)
      @item = item
      @file = file
    end

    def call
      validate!
      delete_existing_file
      write_file

      @item.update(
        photo_filename: @file.original_filename,
        photo_content_type: @file.content_type,
        photo_byte_size: @file.size
      )
      @item
    end

    private

    def validate!
      unless ALLOWED_CONTENT_TYPES.include?(@file.content_type)
        raise ValidationError.new(details: [{ field: "photo", message: "must be a JPEG, PNG, WEBP, or GIF image" }])
      end

      return unless @file.size > MAX_BYTES

      raise ValidationError.new(details: [{ field: "photo", message: "must be #{MAX_BYTES / 1.megabyte}MB or smaller" }])
    end

    def delete_existing_file
      FileUtils.mkdir_p(self.class.storage_dir)
      Dir.glob(self.class.storage_dir.join("#{@item.public_id}.*")).each { |path| File.delete(path) }
    end

    def write_file
      path = self.class.storage_dir.join("#{@item.public_id}#{File.extname(@file.original_filename)}")
      File.open(path, "wb") { |f| f.write(@file.read) }
    end
  end
end
