import { apiFetch } from '@/lib/api'
import { ProjectSchema, ProjectListSchema } from '@/models/project'

const BASE = '/api/v1/admin/projects'

export function listProjects({ token, projectId }) {
  return apiFetch(BASE, { token, projectId }).then((data) => ProjectListSchema.parse(data).projects)
}

export function createProject(input, { token, projectId }) {
  return apiFetch(BASE, { method: 'POST', token, projectId, body: input }).then((data) => ProjectSchema.parse(data))
}

export function updateProject(id, input, { token, projectId }) {
  return apiFetch(`${BASE}/${id}`, { method: 'PATCH', token, projectId, body: input }).then((data) => ProjectSchema.parse(data))
}
