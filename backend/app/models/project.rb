# frozen_string_literal: true

require "tzinfo"

class Project < Sequel::Model
  PUBLIC_ID_PREFIX = "proj"
  # Full IANA identifier list (not ActiveSupport::TimeZone's ~150-entry curated
  # MAPPING) so this never rejects a zone the frontend's timezone picker offers
  # — that picker is built from Intl.supportedValuesOf('timeZone'), and
  # TZInfo's list is a confirmed superset of it.
  TIMEZONES = TZInfo::Timezone.all_identifiers.freeze
  # ISO 4217 active currency codes. No currency gem in the Gemfile — unlike
  # timezone data (which needs TZInfo for DST-rule accuracy), this list is
  # static enough to hardcode directly rather than add a dependency for it.
  # Matches what the frontend's Intl.supportedValuesOf('currency') returns.
  CURRENCIES = %w[
    AED AFN ALL AMD ANG AOA ARS AUD AWG AZN BAM BBD BDT BGN BHD BIF BMD BND
    BOB BRL BSD BTN BWP BYN BZD CAD CDF CHF CLP CNY COP CRC CUP CVE CZK DJF
    DKK DOP DZD EGP ERN ETB EUR FJD FKP GBP GEL GHS GIP GMD GNF GTQ GYD HKD
    HNL HTG HUF IDR ILS INR IQD IRR ISK JMD JOD JPY KES KGS KHR KMF KPW KRW
    KWD KYD KZT LAK LBP LKR LRD LSL LYD MAD MDL MGA MKD MMK MNT MOP MRU MUR
    MVR MWK MXN MYR MZN NAD NGN NIO NOK NPR NZD OMR PAB PEN PGK PHP PKR PLN
    PYG QAR RON RSD RUB RWF SAR SBD SCR SDG SEK SGD SHP SLE SOS SRD SSP STN
    SYP SZL THB TJS TMT TND TOP TRY TTD TWD TZS UAH UGX USD UYU UZS VES VND
    VUV WST XAF XCD XOF XPF YER ZAR ZMW ZWL
  ].freeze

  include PublicIdentifiable
  include BoundedFieldValidatable

  plugin :timestamps, update_on_create: true
  plugin :validation_helpers
  plugin :association_dependencies

  many_to_one :account
  one_to_many :project_memberships
  one_to_many :api_keys
  one_to_many :discounts
  one_to_many :customers
  one_to_many :custom_attributes
  one_to_many :orders
  one_to_many :campaigns
  one_to_many :membership_schemes
  one_to_many :gift_shop_items

  add_association_dependencies project_memberships: :destroy,
                                api_keys: :destroy,
                                discounts: :destroy,
                                customers: :destroy,
                                custom_attributes: :destroy,
                                orders: :destroy,
                                campaigns: :destroy,
                                membership_schemes: :destroy,
                                gift_shop_items: :destroy

  def validate
    super
    validates_presence [:name, :account_id]
    validates_utf8_length :name, max: 1000
    validates_unique %i[account_id name] unless errors[:name]
    validates_includes TIMEZONES, :timezone, allow_missing: true
    validates_includes CURRENCIES, :currency, allow_missing: true
  end
end
