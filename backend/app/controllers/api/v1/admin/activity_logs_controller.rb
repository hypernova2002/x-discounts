# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ActivityLogsController < BaseController
        before_action :require_project_context!

        def index
          dataset = current_project.activity_logs_dataset.order(Sequel.desc(:id))
          # NOTE: query param is `log_action`, not `action` — `params[:action]` is
          # Rails' own reserved routing param (always "index" here), so using
          # that name would silently self-filter to zero rows on every request.
          dataset = dataset.where(entity_type: params[:entity_type]) if params[:entity_type].present?
          dataset = dataset.where(action: params[:log_action]) if params[:log_action].present?
          dataset = dataset.where(user_id: params[:user_id]) if params[:user_id].present?
          if params[:from].present?
            from_date = Date.iso8601(params[:from])
            dataset = dataset.where { created_at >= from_date }
          end
          if params[:to].present?
            to_date = Date.iso8601(params[:to]) + 1
            dataset = dataset.where { created_at < to_date }
          end

          pagy, logs = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { activity_logs: ActivityLogResource.new(logs).to_h, meta: meta_for(pagy) }
        end
      end
    end
  end
end
