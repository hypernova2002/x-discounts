# frozen_string_literal: true

module Exports
  # Shared filename builder for CSV/zip export downloads, e.g.
  # Exports::Filename.build("acme", "campaigns", ext: "csv") => "acme-campaigns-20260916.csv".
  # Used by Exports::GenerateService (background) — previously lived as a
  # controller-only helper when every export was generated synchronously.
  module Filename
    def self.build(*parts, ext:)
      slug = parts.join("-").downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
      "#{slug}-#{Time.now.utc.strftime('%Y%m%d')}.#{ext}"
    end
  end
end
