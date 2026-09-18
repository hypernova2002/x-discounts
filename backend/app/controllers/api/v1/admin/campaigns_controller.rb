# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CampaignsController < BaseController
        WRITE_ROLES = %w[admin developer marketer].freeze

        before_action :require_project_context!
        before_action -> { require_role!(*WRITE_ROLES) }, only: %i[create update]
        before_action :set_campaign, only: %i[show update]

        def index
          dataset = filtered_campaigns_dataset
          pagy, campaigns = paginate(dataset, limit: params[:per_page]&.to_i)
          response.headers.merge!(pagy_headers_merge(pagy))
          render json: { campaigns: CampaignResource.new(campaigns).to_h, meta: meta_for(pagy) }
        end

        def show
          render json: CampaignResource.new(@campaign).to_h
        end

        def export
          send_data Exports::CsvBuilder.build(filtered_campaigns_dataset),
                     type: "text/csv",
                     filename: export_filename(current_project.name, "campaigns", ext: "csv"),
                     disposition: "attachment"
        end

        def create
          campaign = Campaigns::CreateService.new(project: current_project, request: CampaignRequest.new(body)).call
          render json: CampaignResource.new(campaign).to_h, status: :created
        end

        def update
          campaign = Campaigns::UpdateService.new(campaign: @campaign, request: CampaignUpdateRequest.new(body)).call
          render json: CampaignResource.new(campaign).to_h
        end

        private

        def set_campaign
          @campaign = current_project.campaigns_dataset.first(public_id: params[:id])
          raise ApiError.new(:not_found) unless @campaign
        end

        def filtered_campaigns_dataset
          dataset = current_project.campaigns_dataset.order(Sequel.desc(:id))
          dataset = dataset.where(archived: false) unless ActiveModel::Type::Boolean.new.cast(params[:include_archived])
          dataset
        end
      end
    end
  end
end
