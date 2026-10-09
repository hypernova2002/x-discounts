# frozen_string_literal: true

module Exports
  # Builds the actual file for one Export row and updates it with the result —
  # called from ExportJob, but kept separate from it so the generation logic
  # itself stays plain and directly testable. Reuses the same CsvBuilder/
  # ProjectExporter every export type already used when this was synchronous;
  # only the dataset-filtering (previously inline in each controller) moves
  # here, driven by the row's own `params` instead of live request params.
  class GenerateService
    STORAGE_DIR = Rails.root.join("storage", "exports")

    def initialize(export:)
      @export = export
      @project = export.project
    end

    def call
      content, ext = build

      FileUtils.mkdir_p(STORAGE_DIR)
      filename = Exports::Filename.build(@project.name, label, ext: ext)
      path = STORAGE_DIR.join("#{@export.public_id}.#{ext}")
      File.binwrite(path, content)

      @export.update(
        status: "completed",
        filename: filename,
        content_type: ext == "zip" ? "application/zip" : "text/csv",
        byte_size: content.bytesize,
        completed_at: Time.now.utc
      )
    rescue StandardError => e
      @export.update(status: "failed", error_message: e.message)
    end

    private

    def label
      @export.export_type == "project" ? "export" : @export.export_type
    end

    def build
      case @export.export_type
      when "campaigns" then [Exports::CsvBuilder.build(campaigns_dataset), "csv"]
      when "customers" then [Exports::CsvBuilder.build(customers_dataset, foreign_keys: { membership_tier_id: MembershipTier }), "csv"]
      when "orders" then [Exports::CsvBuilder.build(orders_dataset, foreign_keys: { customer_id: Customer }), "csv"]
      when "project" then [Exports::ProjectExporter.new(project: @project).call, "zip"]
      else raise ArgumentError, "unknown export_type #{@export.export_type.inspect}"
      end
    end

    def campaigns_dataset
      dataset = @project.campaigns_dataset.order(Sequel.desc(:id))
      dataset = dataset.where(archived: false) unless ActiveModel::Type::Boolean.new.cast(@export.params["include_archived"])
      dataset
    end

    def customers_dataset
      dataset = @project.customers_dataset.order(Sequel.desc(:id))
      q = @export.params["q"]
      if q.present?
        dataset = dataset.where(
          Sequel.ilike(:external_id, "%#{q}%") |
          Sequel.ilike(:name, "%#{q}%") |
          Sequel.ilike(:email, "%#{q}%")
        )
      end
      dataset
    end

    def orders_dataset
      dataset = @project.orders_dataset.order(Sequel.desc(:id))
      customer_external_id = @export.params["customer_external_id"]
      if customer_external_id.present?
        dataset = dataset.where(customer_id: @project.customers_dataset.where(external_id: customer_external_id).select(:id))
      end
      dataset
    end
  end
end
