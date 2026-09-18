# frozen_string_literal: true

# FactoryBot's default `create` strategy calls #save! — Sequel::Model doesn't define
# that (its plain #save already raises on failure by default, same semantics).
Sequel::Model.class_eval do
  alias_method :save!, :save unless method_defined?(:save!)
end
