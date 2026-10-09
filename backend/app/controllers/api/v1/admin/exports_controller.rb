# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ExportsController < BaseController
        before_action :require_project_context!
        before_action :set_export, only: %i[show download]

        def index
          dataset = current_project.exports_dataset.order(Sequel.desc(:id))
          pagy, exports = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { exports: ExportResource.new(exports).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: ExportResource.new(@export).to_h
        end

        def create
          export_type = body[:export_type]
          unless Export::TYPES.include?(export_type)
            raise ValidationError.new(details: [{ field: "export_type", message: "must be one of #{Export::TYPES.join(', ')}" }])
          end

          export = Export.create(
            project: current_project,
            user: current_user,
            export_type: export_type,
            status: "pending",
            params: body[:params] || {}
          )
          ExportJob.perform_later(export.id)

          render json: ExportResource.new(export).to_h, status: :created
        end

        def download
          raise ApiError.new(:not_found) unless @export.completed?

          send_file @export.file_path.to_s, type: @export.content_type, filename: @export.filename, disposition: "attachment"
        end

        private

        def set_export
          @export = current_project.exports_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @export
        end
      end
    end
  end
end
