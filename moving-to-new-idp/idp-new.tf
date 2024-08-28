resource "auth0_tenant" "IdP" {
  provider = auth0.idp

  friendly_name = "SAML Migration IdP Tenant"
  flags {
    enable_client_connections = false
  }
}

resource "auth0_client" "idp" {
  provider = auth0.idp

  name = "SAML IdP 1 for ${var.okta_org_name}.${var.okta_base_url}"

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
  email           = var.sample_user_email
  given_name      = "Amin"
  family_name     = "Abbaspour"
  password        = var.sample_user_password
}


