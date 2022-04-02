terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.0.6"
    }
  }
}

provider "boundary" {
  addr             = "http://10.5.0.5:9200"
  recovery_kms_hcl = <<EOT
kms "aead" {
  purpose = "recovery"
  aead_type = "aes-gcm"
  key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
  key_id = "global_recovery"
}
EOT
}

variable "users" {
  type = set(string)
  default = [
    "jeff",
    "mike",
    "todd",
  ]
}

resource "boundary_scope" "global" {
  global_scope = true
  name         = "global"
  scope_id     = "global"
}

resource "boundary_scope" "lab" {
  scope_id    = boundary_scope.global.id
  name        = "Lab"
  description = "Organization for testing purposes"
}

resource "boundary_scope" "internal" {
  name                     = "Internal"
  description              = "Project for internal targets"
  scope_id                 = boundary_scope.lab.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_auth_method" "password" {
  name        = "password"
  description = "Password auth method for lab organization"
  type        = "password"
  scope_id    = boundary_scope.lab.id
}

resource "boundary_user" "user" {
  for_each = var.users

  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account.user[each.value].id]
  scope_id    = boundary_scope.lab.id
}

resource "boundary_account" "user" {
  for_each = var.users

  type           = "password"
  auth_method_id = boundary_auth_method.password.id
  login_name     = lower(each.key)
  password       = "password"
  description    = "User account for ${each.key}"
}

resource "boundary_role" "global_anon_listing" {
  scope_id = boundary_scope.global.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}

resource "boundary_role" "org_anon_listing" {
  scope_id = boundary_scope.lab.id
  grant_strings = [
    "id=*;type=auth-method;actions=list,authenticate",
    "type=scope;actions=list",
    "id={{account.id}};actions=read,change-password"
  ]
  principal_ids = ["u_anon"]
}

resource "boundary_role" "org_admin" {
  scope_id       = "global"
  grant_scope_id = boundary_scope.lab.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}

resource "boundary_role" "proj_admin" {
  scope_id       = boundary_scope.lab.id
  grant_scope_id = boundary_scope.internal.id
  grant_strings  = ["id=*;type=*;actions=*"]
  principal_ids = concat(
    [for user in boundary_user.user : user.id],
    ["u_auth"]
  )
}

resource "boundary_host_catalog_static" "sites" {
  name        = "sites"
  description = "Internals HTTP targets"
  scope_id    = boundary_scope.internal.id
}

resource "boundary_host_static" "test_example_com" {
  type            = "static"
  name            = "test.example.com"
  address         = "test.example.com"
  host_catalog_id = boundary_host_catalog_static.sites.id
}

resource "boundary_host_static" "restricted_example_com" {
  type            = "static"
  name            = "restricted.example.com"
  address         = "restricted.example.com"
  host_catalog_id = boundary_host_catalog_static.sites.id
}

resource "boundary_host_set_static" "sites" {
  type            = "static"
  name            = "sites"

  # convention over configuration
  # cidadel_acl expect use this value to filter HTTP targets
  description     = "HTTP"
 
  host_catalog_id = boundary_host_catalog_static.sites.id

  host_ids = [
    boundary_host_static.test_example_com.id,
    boundary_host_static.restricted_example_com.id,
  ]
}

resource "boundary_target" "sites" {
  type                     = "tcp"
  name                     = "sites"
  scope_id                 = boundary_scope.internal.id
  session_connection_limit = -1
  session_max_seconds      = 3600
  default_port             = 80
  host_source_ids = [
    boundary_host_set_static.sites.id,
  ]
}

resource "boundary_host_catalog_static" "proxies" {
  name        = "proxies"
  description = "Internals proxies"
  scope_id    = boundary_scope.internal.id
}

resource "boundary_host_static" "squid" {
  type            = "static"
  name            = "squid"
  address         = "10.5.0.10"
  host_catalog_id = boundary_host_catalog_static.proxies.id
}

resource "boundary_host_set_static" "squid" {
  type            = "static"
  name            = "squid"
  description     = "Host Set squid proxies"
  host_catalog_id = boundary_host_catalog_static.proxies.id

  host_ids = [
    boundary_host_static.squid.id,
  ]
}

resource "boundary_target" "squid" {
  type                     = "tcp"
  name                     = "squid"
  scope_id                 = boundary_scope.internal.id
  session_connection_limit = -1
  session_max_seconds      = 24 * 60 * 60
  default_port             = 3128
  host_source_ids = [
    boundary_host_set_static.squid.id,
  ]
}