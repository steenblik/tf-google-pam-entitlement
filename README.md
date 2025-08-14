## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_folder_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_organization_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_privileged_access_manager_entitlement.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/privileged_access_manager_entitlement) | resource |
| [google_project_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_organization.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_entitlement_config"></a> [entitlement\_config](#input\_entitlement\_config) | Configuration details of the entitlement to create.<br/><br/>**name** (string): The name to give to the PAM entitlement.<br/><br/>**max\_request\_duration** (string): Length of time the entitlement grant is valid for. Specified in seconds. (default: `3600s`)<br/><br/>**eligible\_principals** (list(string)):  A list of principals (users or groups) that can request grants from this entitlement. Must include the IAM principal type prefix (eg user: or group:).<br/><br/>**roles** (list(object)): A list of objects containing the IAM roles & conditions granted with the entitlement. `role` must be in the format roles/<role> (eg. roles/storage.admin).<br/><br/>**condition** (string): An optional IAM condition apply to the role assignment.<br/><br/>**approval\_workflow** (object): An object defining the approval requirements.<br/><br/>**justification\_required** (bool): Whether the requestor neeeds to provide a justification for their request. | <pre>object({<br/>    name                 = string<br/>    max_request_duration = optional(string, "7200s") # e.g., "3600s" is 1 hour<br/>    eligible_principals  = list(string)              # e.g., ["user:joe@acme.com", "group:my-team@acme.com"]<br/>    roles = list(object({<br/>      role                 = string           # e.g., roles/storage.admin<br/>      condition_expression = optional(string) # IAM condition expression<br/>    }))<br/><br/>    # Optional Approval Workflow Configuration<br/>    approval_workflow = optional(object({<br/>      manual_approvals = object({<br/>        require_approver_justification = optional(bool, false) # Does the approver need to give their justification for approving?<br/>        steps = list(object({<br/>          approvers                 = list(string)               # Principals who can approve<br/>          approver_email_recipients = optional(list(string), []) # Additional emails for notifications<br/>        }))<br/>      })<br/>    }), null)<br/><br/>    justification_required = optional(bool, true)<br/>  })</pre> | n/a | yes |
| <a name="input_organization_domain"></a> [organization\_domain](#input\_organization\_domain) | The domain name of the organization. Used to look up the Organization ID to determine the service agent email address. | `string` | n/a | yes |
| <a name="input_parent_scope"></a> [parent\_scope](#input\_parent\_scope) | The scope at which the entitlement is created. 'type' can be 'organization', 'folder', or 'project'. 'id' is required for folder/project types. If type is 'organization', 'id' is optional if 'organization\_domain' is provided.<br/><br/>**type** (string): Can be, organization, folder, or project.<br/><br/>**id** (string): The organization, folder, or project id corresponding with the type selected. This is optional for organization.<br/><br/>**add\_service\_agent\_role** (bool): Whether or not to assign the privilegedaccessmanager.serviceAgent role to the service agent. There is a possibility that another process is assigning this role. (default: `true`). | <pre>object({<br/>    type                   = string<br/>    id                     = optional(string)<br/>    add_service_agent_role = optional(bool, true) # Optional: Add the privilegedaccessmanager.serviceAgent role to the service agent. This role may be managed elsewhere, which is why it is optional<br/>  })</pre> | n/a | yes |

## Outputs

No outputs.
