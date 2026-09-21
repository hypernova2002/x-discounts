# frozen_string_literal: true

# Adds the one extra field campaign#show needs (a real aggregate query) on top of
# CampaignResource's plain fields — kept as a separate class rather than a flag on
# CampaignResource so the aggregate never accidentally runs on list views or on the
# nested `campaign` attribute DiscountResource already embeds via CampaignResource.
class CampaignSummaryResource < CampaignResource
  attribute(:discount_summary) { |campaign| campaign.discount_summary }
end
