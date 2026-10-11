# frozen_string_literal: true

# Counts SQL statements Sequel issues during a block — used by the
# includes=-driven N+1 regression specs to assert query count stays flat as
# row count grows, instead of just asserting on response values.
module QueryCounter
  # Sequel logs each query by calling info/warn/error (depending on level) on
  # every registered logger — not a dedicated "query executed" callback — so
  # this just counts calls to any of them.
  Counter = Struct.new(:count) do
    %i[info warn error debug].each do |level|
      define_method(level) { |*| self.count += 1 }
    end
  end

  def count_queries
    counter = Counter.new(0)
    Sequel::Model.db.loggers.push(counter)
    yield
    counter.count
  ensure
    Sequel::Model.db.loggers.delete(counter)
  end
end

RSpec.configure do |config|
  config.include QueryCounter, type: :request
end
