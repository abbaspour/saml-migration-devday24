# Solution S1: turn your current SP into IdP
resource "auth0_connection" "okta-saml" {
  provider = auth0.sp

  name           = local.saml_connection_name
  strategy       = "samlp"
  display_name   = "Okta SAML Connection 2 to ${var.okta_org_name}"
  show_as_button = true

  options {
    debug                    = false
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    /*
    sign_in_endpoint = okta_app_saml.saml-app-current.http_post_binding
    issuer = okta_app_saml.saml-app-current.entity_url
    protocol_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    */
    metadata_xml = file("okta-idp-2-metadata.xml")
    set_user_root_attributes = "on_each_login"

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oidc"
      client_authorize_query = "type=id_token&timeout=30"
    }
  }
}

resource "auth0_connection_clients" "Okta-SAML-app-assignment" {
  provider = auth0.sp

  connection_id = auth0_connection.okta-saml.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}

resource "okta_app_saml" "saml-app-current" {
  label                    = "SAML App 2 for ${var.auth0_sp_tenant_name}"
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
  name                      = "Send all to IdP 2 ${var.auth0_idp_domain}"
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