resource "auth0_tenant" "IdP" {
  provider = auth0.idp

  friendly_name = "SAML Migration IdP Tenant"
  flags {
    enable_client_connections = false
  }
}

resource "auth0_client" "idp" {
  provider = auth0.idp

  name = "SAML IdP 2 for ${var.okta_org_name}.${var.okta_base_url}"

  callbacks = [
    "https://${var.okta_org_name}.${var.okta_base_url}/sso/saml2/0oagomz7l7LjsZ8Jp1d7"  #cycle dependency
  ]

  addons {
    samlp {
      signature_algorithm = "rsa-sha256"
      name_identifier_probes = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
      mappings = {
        "given_name" : "firstName", "family_name" : "lastName", "email" : "email"
      }
    }
  }
}

locals {
  db-name = "auth0-is-new-sp-users"
}

resource "auth0_connection" "db" {
  provider = auth0.idp
  name     = local.db-name
  strategy = "auth0"
  options {
    brute_force_protection = false
    password_complexity_options {
      min_length = 8
    }
    password_policy = "low"
  }
}

resource "auth0_connection_clients" "enable-idp-app-for-default-db" {
  provider = auth0.idp

  connection_id = auth0_connection.db.id

  enabled_clients = [
    var.auth0_idp_tf_client_id,
    auth0_client.idp.client_id,
    auth0_client.idp-for-kc.client_id
  ]
}

resource "auth0_user" "user1" {
  provider = auth0.idp

  connection_name = local.db-name
  email           = var.sample_user_email
  password        = var.sample_user_password
  given_name      = "Amin"
  family_name     = "Abbaspour"
}

locals {
  cert-name = "auth0-is-new-sp"
}

# in ca/ folder run /self-sign.sh -n ${cert-name} to generate these files

data "local_file" "cert_pem_file" {
  filename = "../ca/${local.cert-name}-cert.pem"
}

data "local_file" "key_pem_file" {
  filename = "../ca/${local.cert-name}-private.pem"
}

data "local_file" "cert_x5c_file" {
  filename = "../ca/${local.cert-name}-cert.x5c"
}

/*resource "null_resource" "cert_strip_pem" {
  provisioner "local-exec" {
    command = <<EOT
      cat ${data.local_file.cert_pem_file.filename} | \
      awk 'NR>1 && !/^-----END/ {printf "%s", $0}' > /tmp/auth0-is-new-sp-cert.x5c
    EOT
  }
}

data "local_file" "cert_x5c" {
  depends_on = [null_resource.cert_strip_pem]
  filename = "/tmp/auth0-is-new-sp-cert.x5c"
}
*/

locals {
  signingCert = replace(data.local_file.cert_pem_file.content, "\n", "\\n")
  signingKey = replace(data.local_file.key_pem_file.content, "\n", "\\n")
}

resource "auth0_action" "kc-saml-change-singing-key" {
  provider = auth0.idp

  name    = "okta-saml-change-singing-key"
  runtime = "node18"
  deploy  = true

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }


  code = templatefile("saml-response-change-signing.js",
    {
      samlIdpClientId = auth0_client.idp.client_id
      signingCert     = local.signingCert
      signingKey      = local.signingKey
    })
}

resource "auth0_trigger_actions" "login_flow" {
  provider = auth0.idp
  trigger  = "post-login"

  actions {
    id           = auth0_action.kc-saml-change-singing-key.id
    display_name = auth0_action.kc-saml-change-singing-key.name
  }
}

resource "auth0_client" "idp-for-kc" {
  provider = auth0.idp

  name = "SAML IdP 2 for ${var.kc_url}"

  callbacks = [
    "http://localhost:8080/realms/master/broker/IdP-amin-saml-idp.au.auth0.com/endpoint"
  ]

  addons {
    samlp {
      signature_algorithm = "rsa-sha256"
      name_identifier_probes = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
      mappings = {
        "given_name" : "firstName", "family_name" : "lastName", "email" : "email"
      }
    }
  }
}

resource "okta_app_signon_policy" "only_1fa" {
  name        = "1FA policy for apps"
  description = "Authentication Policy to be used simple apps."
}

resource "okta_app_signon_policy_rule" "only_1fa_rule" {
  policy_id                   = okta_app_signon_policy.only_1fa.id
  name                        = "Password only"
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

locals {
  kc_okta_broker_alias = "IdP-${var.okta_org_name}.${var.okta_base_url}"
  kc_okta_unsigned_broker_alias = "IdP-unsigned-${var.okta_org_name}.${var.okta_base_url}"
}


resource "okta_app_saml" "saml-app-kc" {
  label = "SAML App for KC ${var.kc_url}"

  sso_url              = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
  destination          = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
  recipient            = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
  audience             = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
  single_logout_issuer = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"
  single_logout_url    = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_broker_alias}/endpoint"

  subject_name_id_template = "$${user.userName}"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  digest_algorithm         = "SHA256"
  honor_force_authn        = false
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  implicit_assignment      = true

  saml_signed_request_enabled = true
  single_logout_certificate = file("../moving-to-new-idp/kc-idp-cert.x5c")

  authentication_policy = okta_app_signon_policy.only_1fa.id
}

resource "local_file" "okta-idp-metadata-kc-app-cert" {
  content  = okta_app_saml.saml-app-kc.certificate
  filename = "okta-idp-metadata-app-kc-cert.pem"
}


resource "okta_app_saml" "saml-app-kc-unsigned" {
  label = "Unsigned Req SAML App for KC ${var.kc_url}"

  sso_url              = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_unsigned_broker_alias}/endpoint"
  destination          = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_unsigned_broker_alias}/endpoint"
  recipient            = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_unsigned_broker_alias}/endpoint"
  audience             = "${var.kc_url}/realms/${var.kc_realm}/broker/${local.kc_okta_unsigned_broker_alias}/endpoint"

  subject_name_id_template = "$${user.userName}"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  digest_algorithm         = "SHA256"
  honor_force_authn        = false
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  implicit_assignment      = true

  saml_signed_request_enabled = false

  authentication_policy = okta_app_signon_policy.only_1fa.id
}

resource "local_file" "okta-idp-metadata-kc-unsigned-app-cert" {
  content  = okta_app_saml.saml-app-kc-unsigned.certificate
  filename = "okta-idp-metadata-app-kc-unsigned-cert.pem"
}


resource "local_file" "okta-idp-metadata-kc-unsigned-app" {
  content  = okta_app_saml.saml-app-kc-unsigned.metadata
  filename = "okta-idp-metadata-app-kc-unsigned.xml"
}

