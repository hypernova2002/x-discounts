import { z } from 'zod'

// Mirrors ApplicationController#meta_for (backend/app/controllers/application_controller.rb)
// — every paginated list response's `meta` object.
export const ListMetaSchema = z.object({
  page: z.number(),
  pages: z.number(),
  count: z.number(),
})

export type ListMeta = z.infer<typeof ListMetaSchema>

// Shared return shape for every paginated `listX()` api function — callers
// that just want "everything" (e.g. populating a dropdown with perPage: 500)
// read `.items`; callers driving a real BaseTable pager also read `.meta`.
export interface PaginatedResult<T> {
  items: T[]
  meta: ListMeta
}
