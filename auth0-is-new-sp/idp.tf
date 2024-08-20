resource "auth0_tenant" "IdP" {
  provider = auth0.idp

  friendly_name = "SAML Migration IdP Tenant"
  flags {
    enable_client_connections = false
  }
}

data "local_file" "cert_pem_file" {
  filename = "../ca/auth0-is-new-sp-cert.pem"
}

data "local_file" "key_pem_file" {
  filename = "../ca/auth0-is-new-sp-private.pem"
}

resource "null_resource" "cert_strip_pem" {
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
  ]
}
resource "auth0_user" "user1" {
  provider = auth0.idp

  connection_name = local.db-name
  email           = "amin@atko.email"
  password        = "amin@atko.email"
  given_name      = "Amin"
  family_name     = "Abbaspour"
}

locals {
   signingCert = replace(data.local_file.cert_pem_file.content, "\n", "\\n")
   signingKey = replace(data.local_file.key_pem_file.content, "\n", "\\n")
}

resource "auth0_action" "kc-saml-change-singing-key" {
  provider = auth0.idp

  name = "okta-saml-change-singing-key"
  runtime = "node18"
  deploy  = true

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }


  code = templatefile("saml-response-change-signing.js",
    {
      samlIdpClientId = auth0_client.idp.client_id
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
