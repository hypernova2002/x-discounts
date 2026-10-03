import { apiFetch, type AuthParams } from '@/lib/api'
import { ProjectSchema, ProjectListSchema, type ProjectInput } from '@/models/project'

const BASE = '/api/v1/admin/projects'

export function listProjects({ token, projectId }: AuthParams) {
  return apiFetch(BASE, { token, projectId }).then((data) => ProjectListSchema.parse(data).projects)
}

export function createProject(input: ProjectInput, { token, projectId }: AuthParams) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => ProjectSchema.parse(data))
}

export function updateProject(id: string, input: Partial<ProjectInput>, { token, projectId }: AuthParams) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => ProjectSchema.parse(data))
}
