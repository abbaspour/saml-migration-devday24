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

# these are extracted from KC's realm master.xml
locals {
  signingCert = replace(file("kc-idp-cert.pem"), "\n", "\\n")
  signingKey = replace(file("kc-idp-key.pem"), "\n", "\\n")
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
