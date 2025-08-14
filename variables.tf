variable "parent_scope" {
  description = <<EOT
The scope at which the entitlement is created. 'type' can be 'organization', 'folder', or 'project'. 'id' is required for folder/project types. If type is 'organization', 'id' is optional if 'organization_domain' is provided.

**type** (string): Can be, organization, folder, or project.

**id** (string): The organization, folder, or project id corresponding with the type selected. This is optional for organization.

**add_service_agent_role** (bool): Whether or not to assign the privilegedaccessmanager.serviceAgent role to the service agent. There is a possibility that another process is assigning this role. (default: `true`).
EOT
  type = object({
    type                   = string
    id                     = optional(string)
    add_service_agent_role = optional(bool, true) # Optional: Add the privilegedaccessmanager.serviceAgent role to the service agent. This role may be managed elsewhere, which is why it is optional
  })

  validation {
    condition     = contains(["organization", "folder", "project"], var.parent_scope.type)
    error_message = "The parent_scope.type must be one of 'organization', 'folder', or 'project'."
  }
  validation {
    condition     = var.parent_scope.type == "organization" || var.parent_scope.id != null
    error_message = "parent_scope.id is required when parent_scope.type is 'folder' or 'project'."
  }
}

variable "organization_domain" {
  type        = string
  description = "The domain name of the organization. Used to look up the Organization ID to determine the service agent email address."
}

variable "entitlement_config" {
  description = <<EOT
Configuration details of the entitlement to create.

**name** (string): The name to give to the PAM entitlement.

**max_request_duration** (string): Length of time the entitlement grant is valid for. Specified in seconds. (default: `3600s`)

**eligible_principals** (list(string)):  A list of principals (users or groups) that can request grants from this entitlement. Must include the IAM principal type prefix (eg user: or group:).

**roles** (list(object)): A list of objects containing the IAM roles & conditions granted with the entitlement. `role` must be in the format roles/<role> (eg. roles/storage.admin).

**condition** (string): An optional IAM condition apply to the role assignment.

**approval_workflow** (object): An object defining the approval requirements.

**justification_required** (bool): Whether the requestor neeeds to provide a justification for their request.

EOT
  type = object({
    name                 = string
    max_request_duration = optional(string, "7200s") # e.g., "3600s" is 1 hour
    eligible_principals  = list(string)              # e.g., ["user:joe@acme.com", "group:my-team@acme.com"]
    roles = list(object({
      role                 = string           # e.g., roles/storage.admin
      condition_expression = optional(string) # IAM condition expression
    }))

    # Optional Approval Workflow Configuration
    approval_workflow = optional(object({
      manual_approvals = object({
        require_approver_justification = optional(bool, false) # Does the approver need to give their justification for approving?
        steps = list(object({
          approvers                 = list(string)               # Principals who can approve
          approver_email_recipients = optional(list(string), []) # Additional emails for notifications
        }))
      })
    }), null)

    justification_required = optional(bool, true)
  })

  validation {
    condition     = length(var.entitlement_config.roles) > 0
    error_message = "At least one role must be specified in entitlement_config.roles."
  }
}
