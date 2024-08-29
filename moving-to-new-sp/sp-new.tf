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




