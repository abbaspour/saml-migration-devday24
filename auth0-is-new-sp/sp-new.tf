/*
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
}

output "okta-metadata-url" {
  value = okta_app_saml.saml-app-current.metadata_url
}

# Solution i1: Current IdP is going to act like a SP
data "http" "auth0-jwks" {
  url = "https://${var.auth0_idp_domain}/.well-known/jwks.json"
}

data "jq_query" "extract-first-x5c-from-jwks" {
  data  = data.http.auth0-jwks.response_body
  query = ".keys[0].x5c[0]"
}


resource "okta_idp_saml_key" "auth0-signing-key" {
  x5c = [data.jq_query.extract-first-x5c-from-jwks.result]
}

resource "okta_idp_saml" "auth0" {
  name                     = "IdP ${var.auth0_idp_domain}"
  acs_type                 = "INSTANCE"
  sso_url                  = "https://${var.auth0_idp_domain}/samlp/${auth0_client.idp.client_id}"
  sso_destination          = "https://${var.auth0_idp_domain}"
  sso_binding              = "HTTP-POST"
  username_template        = "idpuser.subjectNameId"
  kid                      = okta_idp_saml_key.auth0-signing-key.kid
  issuer                   = "urn:${var.auth0_idp_domain}"
  request_signature_scope  = "REQUEST"
  response_signature_scope = "ANY"
}

// All Okta org(s) contain only one IdP Discovery Policy
data "okta_policy" "idp_discovery_policy" {
  name = "Idp Discovery Policy"
  type = "IDP_DISCOVERY"
}

output "okta-auth0-idp-id" {
  value = okta_idp_saml.auth0.id
}
resource "okta_policy_rule_idp_discovery" "auth0-saml-idp-routing" {
  policy_id                  = data.okta_policy.idp_discovery_policy.id
  name                      = "Send all traffic to IdP ${var.auth0_idp_domain}"
  idp_id                    = okta_idp_saml.auth0.id
  idp_type                  = "Saml2"
  network_connection        = "ANYWHERE"
  priority                  = 1
  status                    = "ACTIVE"

  app_include {
    id   = okta_app_saml.saml-app-current.id
    type = "APP"
  }
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
*/