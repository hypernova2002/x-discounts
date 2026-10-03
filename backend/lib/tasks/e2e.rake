# frozen_string_literal: true

namespace :e2e do
  # Resets the dedicated E2E fixture project to a clean, known state and prints
  # the data Playwright's global-setup needs to drive the suite. Safe to run
  # repeatedly — destroying the Project cascades (see Project's
  # association_dependencies) to every campaign/discount/customer/order/etc.
  # it owns, so each full test run starts from an empty project.
  #
  # The fixture user has a real password set (unlike db/seeds.rb's founder
  # user, which has none) so the login/OTP specs can exercise the actual
  # sign-in form. A second, separate user is reset here purely for the OTP
  # spec, so enabling OTP there never affects the main fixture user whose
  # token the rest of the suite reuses via Playwright's storageState.
  #
  # Anchored on the user (email has a DB-level unique index, so repeated runs
  # — even racing concurrent ones — always resolve the same row via Sequel's
  # find_or_create-retries-on-violation behavior) rather than independently
  # looking up the Account by name (accounts.name has no such constraint, so
  # two find_or_create(name: ...) calls racing each other can each decide no
  # matching row exists and both insert, leaving the user on one duplicate
  # and a later run's Project on another — a real bug this surfaced).
  task reset: :environment do
    password = "E2ePassword123!"

    user = User.first(email: "e2e@x-discounts.test")
    account = user&.account || Account.find_or_create(name: "E2E Test Account")

    user = User.find_or_create(email: "e2e@x-discounts.test") do |u|
      u.account_id = account.id
      u.name = "E2E Tester"
    end
    user.password = password
    user.password_confirmation = password
    user.save_changes

    otp_user = User.find_or_create(email: "e2e-otp@x-discounts.test") do |u|
      u.account_id = account.id
      u.name = "E2E OTP Tester"
    end
    otp_user.password = password
    otp_user.password_confirmation = password
    otp_user.save_changes
    otp_user.disable_otp! if otp_user.otp_enabled

    # By account, not by name — a settings spec renames the project, so a
    # name-scoped lookup would miss it on the next run and leave an orphan
    # (the same class of bug the account lookup above had to work around).
    # This whole account exists only for E2E fixtures, so destroying every
    # project under it is always safe.
    Project.where(account_id: account.id).all.each(&:destroy)

    project = Project.create(account_id: account.id, name: "E2E Fixture")

    ProjectMembership.find_or_create(project_id: project.id, user_id: user.id) { |m| m.role = "admin" }
    ProjectMembership.find_or_create(project_id: project.id, user_id: otp_user.id) { |m| m.role = "admin" }

    api_key = ApiKey.create_for(project: project, user: user, role: "admin", name: "e2e key")

    fixture = {
      project_id: project.public_id,
      api_key: api_key.raw_token,
      user_email: user.email,
      user_password: password,
      otp_user_email: otp_user.email,
      otp_user_password: password
    }

    puts "E2E_FIXTURE_JSON=#{fixture.to_json}"
  end
end
