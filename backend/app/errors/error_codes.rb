# frozen_string_literal: true

# Single source of truth for API error codes. ApiError reads status/default_message
# from here so every error response — however it's raised — stays in sync.
module ErrorCodes
  REGISTRY = {
    unauthorized: { status: 401, default_message: "Authentication is required." },
    invalid_credentials: { status: 401, default_message: "Email or password is incorrect." },
    forbidden: { status: 403, default_message: "You are not allowed to perform this action." },
    not_found: { status: 404, default_message: "Resource could not be found." },
    project_context_required: { status: 400, default_message: "A project must be selected (send X-Project-Id)." },
    validation_failed: { status: 422, default_message: "One or more fields are invalid." },
    conflict: { status: 409, default_message: "This conflicts with an existing resource." }
  }.freeze
end
