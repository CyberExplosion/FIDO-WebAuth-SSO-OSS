#  FIDO-WebAuth-SSO-OSS
Services and demo applications use to test out FIDO2 passwordless authentication in [Keycloak](https://github.com/keycloak/keycloak) and [Apereo CAS](https://github.com/apereo/cas)

## Directories
Keycloak related folders are folders with names that started with `keycloak-*`. CAS folder starts with `cas-*`. Any other folder name are used by both services to test out single sign-on (SSO).

Due to using the same applications to test out both services, you cannot test both Keycloak and CAS at the same time. I also configure Keycloak and CAS to use the same local ports for configuration and communication. I recommend trying out Keycloak first before moving on to CAS.

## Keycloak
