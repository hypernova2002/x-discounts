# frozen_string_literal: true

require "csv"

module Exports
  # Dumps a Sequel dataset to a CSV string. Raw internal ids never leave this app in an
  # export — the primary key is dropped (or renamed from public_id, where present, to
  # just "id"), and any foreign key column is resolved from the referenced row's raw
  # integer id to that row's own public_id, so exported data stays meaningful (and
  # collision-free to re-import) without ever printing a serial primary key.
  module CsvBuilder
    DEFAULT_DROP = %i[id project_id].freeze
    DEFAULT_RENAME = { public_id: :id }.freeze

    def self.build(dataset, foreign_keys: {})
      columns = dataset.columns - DEFAULT_DROP
      public_id_cache = Hash.new { |h, k| h[k] = {} }

      CSV.generate do |csv|
        csv << columns.map { |column| (DEFAULT_RENAME[column] || column).to_s }
        dataset.each do |row|
          csv << columns.map do |column|
            raw = row[column]
            if foreign_keys.key?(column)
              resolve_public_id(foreign_keys[column], raw, public_id_cache)
            else
              serialize_cell(raw)
            end
          end
        end
      end
    end

    def self.resolve_public_id(model, raw_id, cache)
      return nil if raw_id.nil?

      cache[model].fetch(raw_id) { cache[model][raw_id] = model.where(id: raw_id).get(:public_id) }
    end

    def self.serialize_cell(value)
      if value.respond_to?(:to_hash)
        value.to_hash.to_json
      elsif value.respond_to?(:to_ary)
        value.to_ary.to_json
      elsif value.is_a?(Time) || value.is_a?(DateTime)
        value.iso8601
      else
        value
      end
    end
  end
end
