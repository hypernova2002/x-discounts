# frozen_string_literal: true

module Coupons
  # Same bespoke local-disk pattern as GiftShopItems::AttachPhotoService (this
  # app is Sequel-only, no ActiveStorage) — files live under
  # storage/coupon_designs/<public_id><ext>. Unlike gift shop items, the
  # metadata (filename/content-type/byte-size) isn't stored in real columns —
  # it lives in the discount's own kind_config jsonb, the same free-form bag
  # every other coupon-specific field (issued_from, valid_until, ...) already
  # uses, so this doesn't need a migration.
  class AttachDesignImageService
    ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
    MAX_BYTES = 5.megabytes

    def self.storage_dir
      Rails.root.join("storage", "coupon_designs")
    end

    def initialize(discount:, file:)
      @discount = discount
      @file = file
    end

    def call
      validate!
      delete_existing_file
      write_file

      @discount.update(
        kind_config: @discount.kind_config.merge(
          "design_image_filename" => @file.original_filename,
          "design_image_content_type" => @file.content_type,
          "design_image_byte_size" => @file.size
        )
      )
      @discount
    end

    private

    def validate!
      unless ALLOWED_CONTENT_TYPES.include?(@file.content_type)
        raise ValidationError.new(details: [{ field: "design_image", message: "must be a JPEG, PNG, WEBP, or GIF image" }])
      end

      return unless @file.size > MAX_BYTES

      raise ValidationError.new(details: [{ field: "design_image", message: "must be #{MAX_BYTES / 1.megabyte}MB or smaller" }])
    end

    def delete_existing_file
      FileUtils.mkdir_p(self.class.storage_dir)
      Dir.glob(self.class.storage_dir.join("#{@discount.public_id}.*")).each { |path| File.delete(path) }
    end

    def write_file
      path = self.class.storage_dir.join("#{@discount.public_id}#{File.extname(@file.original_filename)}")
      File.open(path, "wb") { |f| f.write(@file.read) }
    end
  end
end
