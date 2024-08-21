# Bunch of SP applications

resource "auth0_tenant" "SP" {
  provider = auth0.sp

  friendly_name = "SAML Migration SP Tenant"
  flags {
    enable_client_connections = false
  }
}

resource "okta_idp_saml_key" "auth0-signing-key" {
  x5c = [data.local_file.cert_x5c.content]
}

resource "okta_idp_saml" "auth0" {
  name                     = "IdP 2 ${var.auth0_idp_domain}"
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

output "okta_idp_saml_id" {
  value = okta_idp_saml.auth0.id
}

resource "okta_app_oauth" "jwt_io" {
  label                      = "JWT.io Client for IdP 2"
  type                       = "native"
  grant_types = ["password", "implicit", "authorization_code"]
  response_types = ["id_token", "code"]
  token_endpoint_auth_method = "client_secret_basic"
  redirect_uris = ["https://jwt.io"]
  pkce_required              = false
  implicit_assignment        = true

  profile = jsonencode(
    {
      implicitAssignment = true
    }
  )
}


output "okta_jwt_io_client_id" {
  value = okta_app_oauth.jwt_io.client_id
}


data "keycloak_realm" "master" {
  realm = var.kc_realm
}

resource "keycloak_saml_identity_provider" "auth0" {
  realm = data.keycloak_realm.master.id

  alias                      = "IdP-${var.auth0_idp_domain}"
  entity_id                  = "urn:${var.auth0_idp_domain}"
  single_sign_on_service_url = "https://${var.auth0_idp_domain}/samlp/${auth0_client.idp-for-kc.client_id}"
  sync_mode                  = "IMPORT"
}

resource "keycloak_saml_identity_provider" "okta" {
  realm = data.keycloak_realm.master.id

  alias     = local.kc_okta_broker_alias
  # works for KeyCloak 25
  entity_id = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"

  # TODO: not sure how to set idp entity_id here. it should be set to http://www.okta.com/${org_id}
  single_sign_on_service_url = okta_app_saml.saml-app-kc.http_post_binding
  single_logout_service_url = okta_app_saml.saml-app-kc.http_post_binding

  login_hint                    = true
  post_binding_logout           = true
  post_binding_authn_request    = true
  name_id_policy_format         = "Unspecified"
  principal_type                = "SUBJECT"
  authn_context_comparison_type = "exact"

  signing_certificate = file("okta-idp-cert.pem")

  sync_mode             = "IMPORT"
  post_binding_response = true
}

resource "keycloak_openid_client" "jwt_io" {
  realm_id = data.keycloak_realm.master.id

  client_id             = "jwt.io"
  access_type           = "PUBLIC"
  implicit_flow_enabled = true

  valid_redirect_uris = [
    "https://jwt.io"
  ]

}

