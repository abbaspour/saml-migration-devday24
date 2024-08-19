resource "auth0_tenant" "IdP" {
  provider = auth0.idp

  friendly_name = "SAML Migration IdP Tenant"
  flags {
    enable_client_connections = false
  }
}

# Solution i1: Turn the current IdP into an SP Proxy

resource "auth0_client" "idp" {
  provider = auth0.idp

  name = "SAML IdP for ${var.okta_org_name}.${var.okta_base_url}"

  callbacks = [
    #"https://${var.okta_org_name}.${var.okta_base_url}/sso/saml2/${okta_idp_saml.auth0.id}"  #cycle dependency
    "https://${var.okta_org_name}.${var.okta_base_url}/sso/saml2/0oagmbrczkO0aroZM1d7"  #cycle dependency
    //"https://${var.auth0_sp_domain}/login/callback"
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
  default-db-name = "Username-Password-Authentication"
}

data "auth0_connection" "default-db" {
  provider = auth0.idp
  name     = local.default-db-name
}

resource "auth0_connection_clients" "enable-idp-app-for-default-db" {
  provider = auth0.idp

  connection_id = data.auth0_connection.default-db.id

  enabled_clients = [
    var.auth0_idp_tf_client_id,
    auth0_client.idp.client_id,
    auth0_client.mimic-kc-idp.client_id
  ]
}

resource "auth0_user" "user1" {
  provider = auth0.idp

  connection_name = local.default-db-name
  email           = "amin@atko.email"
  password        = "amin@atko.email"
  given_name      = "Amin"
  family_name     = "Abbaspour"
}


# Solution i2: Mimic current IdP by Upload signing key from current IdP to Auth0
resource "auth0_client" "mimic-kc-idp" {
  provider = auth0.idp

  name = "Mimic KeyCload SAML IdP on ${var.kc_url}"

  callbacks = [
    "https://${var.auth0_sp_domain}/login/callback"  #cycle dependency
  ]

  addons {
    samlp {
      issuer              = "http://localhost:8080/realms/master"
      signature_algorithm = "rsa-sha256"
      name_identifier_probes = ["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"]
      mappings = {
        "given_name" : "firstName", "family_name" : "lastName", "email" : "email"
      }
    }
  }
}

locals {
   signingCert = replace(file("kc-idp-cert.pem"), "\n", "\\n")
   signingKey = replace(file("kc-idp-key.pem"), "\n", "\\n")
}

output "signingCert" {
  value = local.signingCert
}

resource "auth0_action" "kc-saml-change-singing-key" {
  provider = auth0.idp

  name = "kc-saml-change-singing-key"
  runtime = "node18"
  deploy  = true

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }


  code = templatefile("saml-response-change-signing.js",
    {
      samlIdpClientId = auth0_client.mimic-kc-idp.client_id
      signingCert = local.signingCert
      signingKey = local.signingKey
    })
}

resource "auth0_trigger_actions" "login_flow" {
  provider = auth0.idp
  trigger = "post-login"

  actions {
    id           = auth0_action.kc-saml-change-singing-key.id
    display_name = auth0_action.kc-saml-change-singing-key.name
  }
}
