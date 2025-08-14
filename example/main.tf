locals {
  org_domain = "acme.com"
}
# Example: Create an Entitlement for Storage Admin access on a Folder
module "folder_storage_admin_pam" {
  source = "../"

  organization_domain = local.org_domain
  parent_scope = {
    type = "folder"
    id   = "2224445553331"
  }
  entitlement_config = {
    name                 = "folder-storage-admin-access"
    max_request_duration = "3600s"                                    # 1 hour
    eligible_principals  = ["group:cloud-admins@${local.org_domain}"] # Use a group
    roles                = [{ role = "roles/admin" }]
    approval_workflow = {
      manual_approvals = {
        require_approver_justification = true
        steps = [{
          approvers                 = ["user:manager@${local.org_domain}"]
          approver_email_recipients = ["managers-manager@${local.org_domain}"] # No 'user:' prefix here
        }]
      }
    }
    justification_required = true
  }
}

# Example: Create another Entitlement for BigQuery Data Owner on a Project
module "project_bigquery_owner_pam" {
  source = "../"

  organization_domain = local.org_domain
  parent_scope = {
    type = "project"
    id   = "my-project"
  }
  entitlement_config = {
    name                = "bigquery-data-owner"
    eligible_principals = ["user:joe@${local.org_domain}"]
    roles               = [{ role = "roles/bigquery.dataOwner" }]

    # No approval workflow, access granted immediately upon request
    approval_workflow = null

    # No justification required in the request
    justification_required = false
  }
}

# Example: Create another Entitlement for Compute Admin on the organization
module "organization_compute_admin_pam" {
  source = "../"

  organization_domain = local.org_domain
  parent_scope = {
    type = "organization"
  }
  entitlement_config = {
    name                = "compute-admin"
    eligible_principals = ["user:jane@${local.org_domain}"]
    roles = [
      { role = "roles/compute.admin" },
      { role = "roles/compute.networkAdmin" },
    ]

    # No approval workflow, access granted immediately upon request
    approval_workflow = null

    # No justification required in the request
    justification_required = false
  }
}
