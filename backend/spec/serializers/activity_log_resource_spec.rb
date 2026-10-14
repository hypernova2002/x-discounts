require "rails_helper"

RSpec.describe ActivityLogResource do
  # ActivityLog rows are normally written via Auditable's db.after_commit hook, which
  # never fires inside a spec's wrapping (rolled-back, never committed) transaction —
  # so this constructs a row directly rather than relying on that real side effect.
  it "renders the log entry's fields" do
    log = ActivityLog.create(project_id: create(:project).id, action: "create", entity_type: "Campaign",
                              entity_id: 1, entity_public_id: "camp_abc123", entity_label: "Summer Sale",
                              actor_label: "jane@example.com", changes: { name: "Summer Sale" }, request_id: "req-1")

    hash = described_class.new(log).to_h

    expect(hash["id"]).to eq(log.public_id)
    expect(hash["action"]).to eq("create")
    expect(hash["entity_type"]).to eq("Campaign")
    expect(hash["entity_public_id"]).to eq("camp_abc123")
    expect(hash["entity_label"]).to eq("Summer Sale")
    expect(hash["actor_label"]).to eq("jane@example.com")
    expect(hash["changes"]).to eq({ "name" => "Summer Sale" })
  end
end
