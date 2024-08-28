---
title: "SAML Migration"
author: "Amin Abbaspour"
institute: "Okta"
topic: "Developer Day 2024"
date: 26 Sep 2024
theme: "Frankfurt"
fontsize: 11pt
urlcolor: red
linkstyle: bold
aspectratio: 169
logo: "./img/title-background.jpg"
section-titles: false
toc: false
---

# Our assumptions in this talk

- You’re coming in with SAML knowledge
- No changes to either SP or IdP side
- Generic and vendor-agnostic using features that most vendors support
- We’ll see 3 solutions for moving IdP and 3 for moving SP


--- 

# Moving to new IdP

![Moving to new IdP](./img/moving-to-new-idp.png)

---

Solution i1: Coexist; Current IdP becomes SP Proxy 
![Current IdP becomes SP](./img/i1-coexist-current-idp-becomes-sp.png)

--- 

Solution i2: Mimic IdP; upload signing key and replay requests
![Mimic IdP](./img/i2-mimic-idp-replay-request.png)

---

Solution i3: SS-SSO; for gradual migration
![SS-SSO](./img/i3-ss-sso.png)

---

# Moving to new SP

![Moving to new SP](./img/moving-to-new-sp.png)

---

Solution s1: Coexist; current SP becomes IdP
![Current SP becomes IdP](./img/s1-coexist-current-sp-becomes-idp.png)

---

Solution s2: Mimic SP; upload signing key and send signed request with new ACS
![Mimic SP](./img/s2-mimic-sp-send-signed-acs.png)

---

Solution s3: Replay response and adjust destination/audience 
![Replay response](./img/s3-replay-response.png)

---
