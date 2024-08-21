# simple SPA client
resource "auth0_client" "jwt-io" {
  provider = auth0.sp

  name            = "JWT.io 2"
  description     = "JWT.io SPA client 2"
  app_type        = "spa"
  oidc_conformant = true
  is_first_party  = true

  callbacks = [
    "https://jwt.io"
  ]

  allowed_logout_urls = [
  ]

  grant_types = [
    "implicit",
  ]

  jwt_configuration {
    alg = "RS256"
  }
}

output "auth0_jwt_io_client_id" {
  value = auth0_client.jwt-io.client_id
}
locals {
  saml_connection_name    = "Okta-SAML-2"
}

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

# Solution s3: signed request for ACS
# we're mimicking keycloak_saml_identity_provider.okta
resource "auth0_connection" "mimic-kc-sp-for-okta-idp" {
  provider = auth0.sp

  name = "Mimics-KC-SP"

  strategy       = "samlp"
  display_name   = "Mimics KC SP ${var.kc_url} for Okta SAML Connection to ${var.okta_org_name}"
  show_as_button = true

  options {
    debug                    = true
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    sign_saml_request        = true

    set_user_root_attributes = "on_each_login"
    protocol_binding         = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"


    signing_key {
      cert = file("../auth0-is-new-idp/tf/kc-idp-cert.pem")
      key  = file("../auth0-is-new-idp/tf/kc-idp-key.pem")
    }

    signing_cert = local_file.okta-idp-metadata-app-cert.content

    issuer = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
    entity_id = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"

    sign_in_endpoint = okta_app_saml.saml-app-kc.http_post_binding

    request_template = <<EOL
<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    AssertionConsumerServiceURL="@@AssertionConsumerServiceURL@@"
    Destination="@@Destination@@"
    ID="@@ID@@"
    IssueInstant="@@IssueInstant@@"
    ProtocolBinding="@@ProtocolBinding@@" Version="2.0">
    <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">@@Issuer@@</saml:Issuer>
    <samlp:NameIDPolicy Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">
    </samlp:NameIDPolicy>
</samlp:AuthnRequest>
EOL

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oidc"
      client_authorize_query = "type=id_token&timeout=30"
    }
  }

}


resource "auth0_connection_clients" "Mimic-KC-SAML-app-assignment" {
  provider = auth0.sp

  connection_id = auth0_connection.mimic-kc-sp-for-okta-idp.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}
