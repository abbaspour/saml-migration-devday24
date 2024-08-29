# Solution s2: signed request for ACS
# we're mimicking keycloak_saml_identity_provider.okta
# https://auth0.com/docs/authenticate/protocols/saml/saml-sso-integrations/sign-and-encrypt-saml-requests#use-a-custom-key-to-sign-requests
resource "auth0_connection" "mimic-kc-sp-for-okta-idp-signed-req" {
  provider = auth0.sp

  name = "Mimics-KC-SP-signed-req"

  strategy       = "samlp"
  display_name   = "Mimics KC SP ${var.kc_url} for Okta SAML Connection to ${var.okta_org_name} by Signed Req"
  show_as_button = true

  options {
    debug                    = true
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    sign_saml_request        = true

    set_user_root_attributes = "on_each_login"
    protocol_binding         = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"


    signing_key {
      cert = file("../moving-to-new-idp/kc-idp-cert.pem")
      key  = file("../moving-to-new-idp/kc-idp-key.pem")
    }

    signing_cert = local_file.okta-idp-metadata-kc-app-cert.content

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

  connection_id = auth0_connection.mimic-kc-sp-for-okta-idp-signed-req.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}
