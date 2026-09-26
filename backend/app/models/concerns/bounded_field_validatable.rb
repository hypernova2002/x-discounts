# frozen_string_literal: true

module BoundedFieldValidatable
  # Presence is handled separately by existing validates_presence calls — this
  # only adds a max length (the real domain constraint, never one blanket
  # number) and rejects unsafe byte content: invalid UTF-8 and embedded null
  # bytes, which Postgres' text columns reject outright with a raw DB error
  # otherwise, so this turns that into a clean validation error instead.
  def validates_utf8_length(field, max:)
    add_utf8_length_errors(field, send(field), max: max)
  end

  # Same check as validates_utf8_length, but against an already-extracted value
  # (e.g. a string nested inside a jsonb column) rather than a model attribute.
  def add_utf8_length_errors(field, value, max:)
    return if value.nil?
    unless value.is_a?(String)
      errors.add(field, "must be a string")
      return
    end
    errors.add(field, "must be valid UTF-8") unless value.valid_encoding?
    errors.add(field, "must not contain null bytes") if value.include?("\0")
    errors.add(field, "is too long (maximum is #{max} characters)") if value.length > max
  end

  # true/false only, not any truthy/falsy value. Skips nil — a DB-defaulted
  # boolean column is legitimately nil in-memory before the row is inserted,
  # since the column default only applies at INSERT time, not at construction.
  def validates_boolean(field)
    value = send(field)
    return if value.nil?
    errors.add(field, "must be true or false") unless [true, false].include?(value)
  end

  # Numeric within a sensible range; integer_only additionally rejects a
  # fractional BigDecimal/Float for count-shaped columns backed by an
  # `integer` DB column.
  def validates_bounded_number(field, min: nil, max: nil, integer_only: false)
    add_bounded_number_errors(field, send(field), min: min, max: max, integer_only: integer_only)
  end

  # Same check as validates_bounded_number, but against an already-extracted
  # value (e.g. a number nested inside a jsonb column) rather than a model attribute.
  def add_bounded_number_errors(field, value, min: nil, max: nil, integer_only: false)
    return if value.nil?
    unless value.is_a?(Numeric)
      errors.add(field, "must be a number")
      return
    end
    if integer_only && !(value.is_a?(Integer) || (value.is_a?(BigDecimal) && value.frac.zero?))
      errors.add(field, "must be a whole number")
      return
    end
    errors.add(field, "must be at least #{min}") if min && value < min
    errors.add(field, "must be at most #{max}") if max && value > max
  end
end
