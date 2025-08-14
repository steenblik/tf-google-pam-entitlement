# Docs
/*
To use this module, the principal running Terraform needs permissions:

1.  To manage PAM Entitlements at the chosen scope:
    - roles/privilegedaccessmanager.admin on the target Organization, Folder, or Project.

2.  To grant IAM roles to the PAM Service Agent at the chosen scope:
    - Typically roles/iam.securityAdmin on the Organization, or
    - roles/resourcemanager.folderAdmin if scoped to a Folder, or
    - roles/resourcemanager.projectIamAdmin if scoped to a Project.
    - Granting roles/iam.securityAdmin at the Organization level is often the simplest.

API Enablement:
The 'privilegedaccessmanager.googleapis.com' API must be enabled in a project within the organization.
This module does NOT handle API enablement.

Service Agent:
PAM uses an Organization-level service agent: <REDACTED_EMAIL>.
This service agent needs the 'roles/privilegedaccessmanager.serviceAgent' role granted AT THE SCOPE
where the entitlements are being managed (Organization, Folder, or Project). This module optionally sets up this grant.
*/

locals {
  org_id      = data.google_organization.this.org_id
  parent_type = var.parent_scope.type
  parent_id   = coalesce(var.parent_scope.id, local.org_id)

  # Format for the 'parent' attribute of the entitlement resource
  parent_string = "${local.parent_type}s/${local.parent_id}"

  # Map parent type to resource manager resource type string
  resource_type_map = {
    organization = "cloudresourcemanager.googleapis.com/Organization"
    folder       = "cloudresourcemanager.googleapis.com/Folder"
    project      = "cloudresourcemanager.googleapis.com/Project"
  }
  resource_type = local.resource_type_map[local.parent_type]

  # Full resource name for the gcp_iam_access block
  resource_name = "//cloudresourcemanager.googleapis.com/${local.parent_string}"

  # PAM service agent always uses the organization ID in its email format.
  service_agent      = "serviceAccount:service-org-${local.org_id}@gcp-sa-pam.iam.gserviceaccount.com"
  service_agent_role = "roles/privilegedaccessmanager.serviceAgent"
}

data "google_organization" "this" {
  domain = var.organization_domain
}

# Grant the PAM Service Agent role AT the var.parent_scope if requested
resource "google_organization_iam_member" "this" {
  count  = local.parent_type == "organization" && var.parent_scope.add_service_agent_role ? 1 : 0
  org_id = local.parent_id
  role   = local.service_agent_role
  member = local.service_agent
}

resource "google_folder_iam_member" "this" {
  count  = local.parent_type == "folder" && var.parent_scope.add_service_agent_role ? 1 : 0
  folder = "folders/${local.parent_id}"
  role   = local.service_agent_role
  member = local.service_agent
}

resource "google_project_iam_member" "this" {
  count   = local.parent_type == "project" && var.parent_scope.add_service_agent_role ? 1 : 0
  project = local.parent_id
  role    = local.service_agent_role
  member  = local.service_agent
}

# Create the PAM Entitlement
resource "google_privileged_access_manager_entitlement" "this" {
  parent         = local.parent_string
  location       = "global"
  entitlement_id = var.entitlement_config.name

  max_request_duration = var.entitlement_config.max_request_duration

  eligible_users {
    principals = var.entitlement_config.eligible_principals
  }

  dynamic "approval_workflow" {
    for_each = var.entitlement_config.approval_workflow != null ? [var.entitlement_config.approval_workflow] : []
    content {
      dynamic "manual_approvals" {
        for_each = approval_workflow.value.manual_approvals != null ? [approval_workflow.value.manual_approvals] : []
        content {
          require_approver_justification = manual_approvals.value.require_approver_justification
          dynamic "steps" {
            for_each = manual_approvals.value.steps
            content {
              approvers {
                principals = steps.value.approvers
              }
              approvals_needed          = 1 # 1 is the only supported value
              approver_email_recipients = steps.value.approver_email_recipients
            }
          }
        }
      }
    }
  }

  requester_justification_config {
    dynamic "unstructured" {
      for_each = var.entitlement_config.justification_required ? [1] : []
      content {}
    }
    dynamic "not_mandatory" {
      for_each = var.entitlement_config.justification_required ? [] : [1]
      content {}
    }
  }

  privileged_access {
    gcp_iam_access {
      resource_type = local.resource_type
      resource      = local.resource_name
      dynamic "role_bindings" {
        for_each = var.entitlement_config.roles
        content {
          role                 = role_bindings.value.role
          condition_expression = role_bindings.value.condition_expression
        }
      }
    }
  }

  depends_on = [
    google_organization_iam_member.this,
    google_folder_iam_member.this,
    google_project_iam_member.this
  ]
}