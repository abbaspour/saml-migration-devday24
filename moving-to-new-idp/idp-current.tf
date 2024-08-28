resource "okta_app_signon_policy" "only_1fa" {
  name        = "1FA policy for apps moving idp"
  description = "Authentication Policy to be used simple apps."
}

resource "okta_app_signon_policy_rule" "only_1fa_rule" {
  policy_id                   = okta_app_signon_policy.only_1fa.id
  name                        = "Password only for auth moving idp"
  factor_mode                 = "1FA"
  re_authentication_frequency = "PT43800H"
  status                      = "ACTIVE"
  constraints = [
    jsonencode({
      "knowledge" : {
        "required" : false
        "types" : ["password"]
      }
    })
  ]
}

resource "okta_app_saml" "saml-app-current" {
  label                    = "SAML App for ${var.auth0_sp_tenant_name}"
  sso_url                  = "https://${var.auth0_sp_domain}/login/callback"
  recipient                = "https://${var.auth0_sp_domain}/login/callback"
  destination              = "https://${var.auth0_sp_domain}/login/callback"
  audience                 = "urn:auth0:${var.auth0_sp_tenant_name}:${local.saml_connection_name}"
  subject_name_id_template = "$${user.userName}"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  digest_algorithm         = "SHA256"
  honor_force_authn        = false
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  implicit_assignment        = true

  authentication_policy = okta_app_signon_policy.only_1fa.id
}

output "okta-saml-app-id" {
  value = okta_app_saml.saml-app-current.id
}
output "okta-metadata-url" {
  value = okta_app_saml.saml-app-current.metadata_url
}

data "keycloak_realm" "master" {
  realm = "master"
}

resource "keycloak_saml_client" "auth0_saml_client" {
  realm_id  = data.keycloak_realm.master.id
  client_id = "urn:auth0:${var.auth0_sp_tenant_name}:${local.kc_saml_connection_name}"
  name      = "auth0-saml-client"

  valid_redirect_uris = [
    "https://${var.auth0_sp_domain}/login/callback"
  ]

  sign_documents          = false
  sign_assertions         = true
  include_authn_statement = true

  client_signature_required = false
}

# need this for /login/signout?fromURI={{one of the trusted origins}}
resource "okta_trusted_origin" "jwt-io" {
  name   = "jwt.io"
  origin = "https://jwt.io"
  scopes = ["REDIRECT"]
}

resource "okta_user" "sample_user" {
  email      = var.sample_user_email
  first_name = "Amin"
  last_name  = "Abbaspour"
  login      = var.sample_user_email
  password = var.sample_user_password
}
