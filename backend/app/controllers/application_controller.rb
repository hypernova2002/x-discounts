class ApplicationController < ActionController::API
  include Authenticatable
  include Pagy::Backend

  rescue_from ApiError, with: :render_api_error

  # Request models (app/request_models) raise these when the incoming JSON doesn't
  # match the expected shape/types — fold them into the same standardized shape.
  rescue_from Dry::Struct::Error, Dry::Types::ConstraintError, Dry::Types::SchemaError, with: :render_request_model_error

  # Last-resort net: a service should rescue Sequel::UniqueConstraintViolation itself and
  # revalidate its models to produce a field-specific ValidationError. Reaching here means
  # that didn't happen (a DB unique index with no matching validates_unique) — not a 500,
  # since the request itself was fine, but logged so the gap gets noticed and fixed.
  rescue_from Sequel::UniqueConstraintViolation, with: :render_unmapped_unique_violation

  private

  def render_api_error(error)
    render json: error.to_response, status: error.status
  end

  def render_request_model_error(exception)
    render_api_error(ValidationError.new(details: [{ field: "base", message: exception.message }]))
  end

  def render_unmapped_unique_violation(exception)
    Rails.logger.warn("Unmapped unique constraint violation: #{exception.message}\n#{exception.backtrace.join("\n")}")
    render_api_error(ApiError.new(:conflict))
  end

  def body
    @body ||= params.to_unsafe_h.with_indifferent_access
  end

  # limit: lets a caller opt into a larger page (capped at 500) than the app-wide
  # default — e.g. a dropdown that needs a whole entity's worth of records to filter
  # client-side, not the first page of it. Omitted, this behaves exactly as before.
  def paginate(dataset, limit: nil)
    pagy(dataset, count: dataset.count, **(limit ? { limit: limit.clamp(1, 500) } : {}))
  end

  def meta_for(pagy)
    { page: pagy.page, pages: pagy.pages, count: pagy.count }
  end

  # Shared filename builder for CSV/zip export downloads, e.g. export_filename("acme",
  # "campaigns", ext: "csv") => "acme-campaigns-20260916.csv".
  def export_filename(*parts, ext:)
    slug = parts.join("-").downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    "#{slug}-#{Time.now.utc.strftime('%Y%m%d')}.#{ext}"
  end
end
