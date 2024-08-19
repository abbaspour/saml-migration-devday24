# Bunch of SP applications

resource "auth0_tenant" "SP" {
  provider = auth0.sp

  friendly_name = "SAML Migration SP Tenant"
  flags {
    enable_client_connections = false
  }
}

locals {
  saml_connection_name    = "Okta-SAML"
  kc_saml_connection_name = "KC-SAML"
}

// Note:
// comment this rest until okta resources are provisioned first
// then visit okta-metadata-url printed in the output as okta org admin and save the file under okta-idp-metadata.xml
// then uncomment and run terraform again
resource "auth0_connection" "okta-saml" {
  provider = auth0.sp

  name           = local.saml_connection_name
  strategy       = "samlp"
  display_name   = "Okta SAML Connection to ${var.okta_org_name}"
  show_as_button = true

  options {
    debug                    = false
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    metadata_xml = file("okta-idp-metadata.xml")
    set_user_root_attributes = "on_each_login"

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oidc"
      client_authorize_query = "type=id_token&timeout=30"
    }
  }
}

resource "auth0_connection" "kc-saml" {
  provider = auth0.sp

  name           = local.kc_saml_connection_name
  strategy       = "samlp"
  display_name   = "KeyCloak SAML Connection to ${var.kc_url}"
  show_as_button = true

  options {
    debug                    = false
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    metadata_xml = file("descriptor.xml")
    //metadata_url             = "${var.kc_url}/realms/master/protocol/saml/descriptor"
    sign_saml_request        = false
    set_user_root_attributes = "on_each_login"
    protocol_binding         = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

    request_template = <<EOL
<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    AssertionConsumerServiceURL="@@AssertionConsumerServiceURL@@"
    Destination="@@Destination@@"
    ID="@@ID@@"
    IssueInstant="@@IssueInstant@@"
    ProtocolBinding="@@ProtocolBinding@@" Version="2.0">
    <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">@@Issuer@@</saml:Issuer>
</samlp:AuthnRequest>
EOL

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oidc"
      client_authorize_query = "type=id_token&timeout=30"
    }
  }
}

# simple SPA client
resource "auth0_client" "jwt-io" {
  provider = auth0.sp

  name            = "JWT.io"
  description     = "JWT.io SPA client"
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


resource "auth0_connection_clients" "Okta-SAML-app-assignment" {
  provider = auth0.sp

  connection_id = auth0_connection.okta-saml.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}

resource "auth0_connection_clients" "KC-SAML-app-assignment" {
  provider = auth0.sp

  connection_id = auth0_connection.kc-saml.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}

### mimic KC
resource "auth0_connection" "mimic-kc-saml" {
  provider = auth0.sp

  name           = "Mimic-${local.kc_saml_connection_name}"
  strategy       = "samlp"
  display_name   = "Mimic KeyCloak SAML Connection to ${var.kc_url}"
  show_as_button = true

  options {
    debug                    = false
    signature_algorithm      = "rsa-sha256"
    digest_algorithm         = "sha256"
    metadata_xml = file("descriptor.xml")
    sign_saml_request        = false
    set_user_root_attributes = "on_each_login"
    protocol_binding         = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"

    ## todo: this is a bug in TF provider. if I pass this, it should override metadata
    sign_in_endpoint = "https://${var.auth0_idp_domain}/samlp/${auth0_client.mimic-kc-idp.client_id}"

    request_template = <<EOL
<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
    AssertionConsumerServiceURL="@@AssertionConsumerServiceURL@@"
    Destination="@@Destination@@"
    ID="@@ID@@"
    IssueInstant="@@IssueInstant@@"
    ProtocolBinding="@@ProtocolBinding@@" Version="2.0">
    <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">@@Issuer@@</saml:Issuer>
</samlp:AuthnRequest>
EOL

    idp_initiated {
      client_id              = auth0_client.jwt-io.client_id
      client_protocol        = "oidc"
      client_authorize_query = "type=id_token&timeout=30"
    }
  }
}

output "mimic-kc-sign_in_url" {
  value = "https://${var.auth0_idp_domain}/samlp/${auth0_client.mimic-kc-idp.client_id}"
}

resource "auth0_connection_clients" "mimic-KC-SAML-app-assignment" {
  provider = auth0.sp

  connection_id = auth0_connection.mimic-kc-saml.id
  enabled_clients = [
    auth0_client.jwt-io.client_id,
    var.auth0_sp_tf_client_id
  ]
}
