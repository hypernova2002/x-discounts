# frozen_string_literal: true

module Exports
  # Full data-model dump of a project: every project-scoped table, one CSV per table,
  # bundled into a single .zip. Tables without a direct project_id are scoped via a
  # subquery on their parent table's project-scoped ids. See CsvBuilder for how raw
  # internal ids are kept out of the output entirely.
  class ProjectExporter
    TABLES = {
      "campaigns" => {
        dataset: ->(project) { project.campaigns_dataset },
      },
      "discounts" => {
        dataset: ->(project) { project.discounts_dataset },
        foreign_keys: { campaign_id: Campaign },
      },
      "discount_effects" => {
        dataset: ->(project) { DiscountEffect.where(discount_id: project.discounts_dataset.select(:id)) },
        foreign_keys: { discount_id: Discount },
      },
      "discount_stacking_compatibilities" => {
        dataset: ->(project) { DiscountStackingCompatibility.where(discount_id: project.discounts_dataset.select(:id)) },
        foreign_keys: { discount_id: Discount, compatible_discount_id: Discount },
      },
      "coupon_codes" => {
        dataset: ->(project) { CouponCode.where(project_id: project.id) },
        foreign_keys: { discount_id: Discount, customer_id: Customer },
      },
      "customers" => {
        dataset: ->(project) { project.customers_dataset },
        foreign_keys: { membership_tier_id: MembershipTier },
      },
      "custom_attributes" => {
        dataset: ->(project) { project.custom_attributes_dataset },
      },
      "membership_schemes" => {
        dataset: ->(project) { project.membership_schemes_dataset },
      },
      "membership_tiers" => {
        dataset: ->(project) { MembershipTier.where(membership_scheme_id: project.membership_schemes_dataset.select(:id)) },
        foreign_keys: { membership_scheme_id: MembershipScheme },
      },
      "gift_shop_items" => {
        dataset: ->(project) { project.gift_shop_items_dataset },
      },
      "gift_shop_redemptions" => {
        dataset: ->(project) { GiftShopRedemption.where(customer_id: project.customers_dataset.select(:id)) },
        foreign_keys: { customer_id: Customer, gift_shop_item_id: GiftShopItem },
      },
      "orders" => {
        dataset: ->(project) { project.orders_dataset },
        foreign_keys: { customer_id: Customer },
      },
      "order_line_items" => {
        dataset: ->(project) { OrderLineItem.where(order_id: project.orders_dataset.select(:id)) },
        foreign_keys: { order_id: Order },
      },
      "order_discounts" => {
        dataset: ->(project) { OrderDiscount.where(order_id: project.orders_dataset.select(:id)) },
        foreign_keys: { order_id: Order, discount_id: Discount, redemption_id: Redemption, loyalty_point_lot_id: LoyaltyPointLot },
      },
      "discount_refunds" => {
        dataset: ->(project) { DiscountRefund.where(order_discount_id: OrderDiscount.where(order_id: project.orders_dataset.select(:id)).select(:id)) },
        foreign_keys: { order_discount_id: OrderDiscount, performed_by_user_id: User },
      },
      "points_redemptions" => {
        dataset: ->(project) { PointsRedemption.where(order_id: project.orders_dataset.select(:id)) },
        foreign_keys: { order_id: Order, customer_id: Customer },
      },
      "redemptions" => {
        dataset: ->(project) { Redemption.where(customer_id: project.customers_dataset.select(:id)) },
        foreign_keys: { customer_id: Customer, discount_id: Discount, coupon_code_id: CouponCode },
      },
      "loyalty_point_lots" => {
        dataset: ->(project) { LoyaltyPointLot.where(customer_id: project.customers_dataset.select(:id)) },
        foreign_keys: { customer_id: Customer, order_id: Order, discount_id: Discount, refund_of_points_redemption_id: PointsRedemption, performed_by_user_id: User },
      },
      "loyalty_point_ledger_entries" => {
        dataset: ->(project) { LoyaltyPointLedgerEntry.where(loyalty_point_lot_id: LoyaltyPointLot.where(customer_id: project.customers_dataset.select(:id)).select(:id)) },
        foreign_keys: { loyalty_point_lot_id: LoyaltyPointLot, points_redemption_id: PointsRedemption, gift_shop_redemption_id: GiftShopRedemption, order_discount_id: OrderDiscount, performed_by_user_id: User },
      },
    }.freeze

    def initialize(project:)
      @project = project
    end

    def call
      buffer = ::Zip::OutputStream.write_buffer do |zip|
        TABLES.each do |table_name, config|
          zip.put_next_entry("#{table_name}.csv")
          dataset = config[:dataset].call(@project)
          zip.write(Exports::CsvBuilder.build(dataset, foreign_keys: config[:foreign_keys] || {}))
        end
      end
      buffer.string
    end
  end
end
