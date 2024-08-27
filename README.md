# SAML Migration Talk - Okta Developer Day 2024 

# Moving to new IdP
![Moving to new IdP](./img/moving-to-new-idp.png)


## Solution i1: Coexist; Current IdP becomes SP Proxy 
![Current IdP becomes SP](./img/i1-coexist-current-idp-becomes-sp.png)

## Solution i2: Mimic IdP; upload signing key and replay requests
![Mimic IdP](./img/i2-mimic-idp-replay-request.png)

## Solution i3: SS-SSO; for gradual migration
![SS-SSO](./img/i3-ss-sso.png)

# Moving to new SP
![Moving to new SP](./img/moving-to-new-sp.png)

## Solution s1: Coexist; current SP becomes IdP
![Current SP becomes IdP](./img/s1-coexist-current-sp-becomes-idp.png)

### Solution s2: Mimic SP; upload signing key and send signed request with new ACS
![Mimic SP](./img/s2-mimic-sp-send-signed-acs.png)

### Solution s3: Replay response and adjust destination/audience 
![Replay response](./img/s3-replay-response.png)


http://localhost:8080/realms/master/protocol/openid-connect/logout
http://localhost:8080/realms/master/protocol/openid-connect/auth?client_id=jwt.io&redirect_uri=https://jwt.io&response_type=id_token&nonce=n1