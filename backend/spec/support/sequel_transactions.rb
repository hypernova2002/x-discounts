# frozen_string_literal: true

# Sequel equivalent of Rails' transactional fixtures — wraps each example in a
# transaction that's always rolled back, so specs don't accumulate data across runs
# (FactoryBot sequences restart at 1 every process, so without this, unique
# constraints like email/key would collide on the second run).
RSpec.configure do |config|
  config.around do |example|
    Sequel::Model.db.transaction(rollback: :always) { example.run }
  end
end
