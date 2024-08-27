terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.10"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.3"
    }
    jq = {
      source  = "massdriver-cloud/jq"
      version = "0.2.1"
    }
    keycloak = {
      source = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}

provider "auth0" {
  alias         = "idp"
  domain        = var.auth0_idp_domain
  client_id     = var.auth0_idp_tf_client_id
  client_secret = var.auth0_idp_tf_client_secret
}

provider "auth0" {
  alias = "sp"

  domain        = var.auth0_sp_domain
  client_id     = var.auth0_sp_tf_client_id
  client_secret = var.auth0_sp_tf_client_secret
}


provider "keycloak" {
  client_id     = var.kc_tf_client_id
  client_secret = var.kc_tf_client_secret
  url           = var.kc_url
}