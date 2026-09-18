# frozen_string_literal: true

account = Account.find_or_create(name: "Acme") { |a| a.name = "Acme" }
user = User.find_or_create(email: "founder@acme.test") do |u|
  u.account_id = account.id
  u.name = "Founder"
end
project = Project.find_or_create(account_id: account.id, name: "Default") do |p|
  p.account_id = account.id
  p.name = "Default"
end
ProjectMembership.find_or_create(project_id: project.id, user_id: user.id) do |m|
  m.role = "admin"
end

api_key = ApiKey.create_for(project: project, user: user, role: "admin", name: "seed key")

puts "Seeded account=#{account.name} project=#{project.name} user=#{user.email}"
puts "API key (save this, it will not be shown again): #{api_key.raw_token}"
