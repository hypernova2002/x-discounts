# frozen_string_literal: true

# Shared `?includes=a,b,c` parsing for every admin API controller — paired with
# ApplicationResource#included? on the serialization side. Controllers use this
# to decide what to eager-load/bulk-compute, then pass `params: { includes:
# requested_includes }` into the top-level resource so the same set reaches
# every nested resource (Alba forwards `params` down the whole tree).
module Includable
  extend ActiveSupport::Concern

  private

  def requested_includes
    @requested_includes ||= params[:includes].to_s.split(",").map(&:strip).reject(&:blank?).to_set
  end
end
