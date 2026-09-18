# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ExportsController < BaseController
        before_action :require_project_context!

        def project
          send_data Exports::ProjectExporter.new(project: current_project).call,
                     type: "application/zip",
                     filename: export_filename(current_project.name, "export", ext: "zip"),
                     disposition: "attachment"
        end
      end
    end
  end
end
