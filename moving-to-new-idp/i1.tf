# Solution i1: Turn the current IdP into an SP Proxy

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
  name                     = "IdP 1 ${var.auth0_idp_domain}"
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

/*
// NOTE: do NOT remove
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
*/