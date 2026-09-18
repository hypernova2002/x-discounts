import { z } from 'zod'

// Refunding a line is always expressed in whichever unit that line earned —
// amount_off (currency) for a plain discount, points for a loyalty line or a
// points redemption (see RefundRequest on the backend, which treats the two as
// mutually exclusive). Only one of those two keys is ever sent, keyed by `unit`.
export function refundInputSchema(t, unit) {
  const amount =
    unit === 'points'
      ? z
          .number({ message: t('orderDetail.refundDialog.amountRequired') })
          .int(t('orderDetail.refundDialog.amountInteger'))
          .positive(t('orderDetail.refundDialog.amountPositive'))
      : z
          .number({ message: t('orderDetail.refundDialog.amountRequired') })
          .positive(t('orderDetail.refundDialog.amountPositive'))

  return z.object({
    [unit]: amount,
    reason: z.string().trim().nullable(),
  })
}
