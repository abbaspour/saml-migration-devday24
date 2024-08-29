## auth0 (idp)
variable "auth0_idp_domain" {
  type        = string
  description = "Auth0 IdP tenant Domain"
}

variable "auth0_idp_tf_client_id" {
  type        = string
  description = "Auth0 IdP tenant TF app client_id"
}

variable "auth0_idp_tf_client_secret" {
  type        = string
  description = "Auth0 IdP tenant TF app client_secret"
  sensitive   = true
}

## auth0 (sp)
variable "auth0_sp_domain" {
  type        = string
  description = "Auth0 SP tenant Domain"
}

variable "auth0_sp_tenant_name" {
  type        = string
  description = "Auth0 SP tenant name"
}

variable "auth0_sp_tf_client_id" {
  type        = string
  description = "Auth0 SP tenant TF app client_id"
}

variable "auth0_sp_tf_client_secret" {
  type        = string
  description = "Auth0 SP tenant TF app client_secret"
  sensitive   = true
}

## okta
variable "okta_org_name" {
  type        = string
  description = "Okta org name"
}

variable "okta_base_url" {
  type        = string
  description = "okta.com | oktapreview.com"
  default     = "okta.com"
}

variable "okta_api_token" {
  type      = string
  sensitive = true
}

## keycloak
variable "kc_url" {
  type        = string
  description = "keycloak deployment url"
  default     = "http://localhost:8080"
}

variable "kc_tf_client_id" {
  type        = string
  description = "keycloak TF client_id"
  default     = "terraform"
}

variable "kc_tf_client_secret" {
  type        = string
  description = "keycloak TF client_secret"
  sensitive   = true
}

variable "kc_realm" {
  type        = string
  description = "KC realm"
  default     = "master"
}

## sample user
variable "sample_user_email" {
  type = string
  description = "sample user email"
}

variable "sample_user_password" {
  type = string
  description = "sample user password"
  sensitive = true
}

