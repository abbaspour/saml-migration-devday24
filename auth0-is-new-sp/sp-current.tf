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
  redirect_uris              = ["https://jwt.io"]
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
