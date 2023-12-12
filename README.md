#  FIDO-WebAuth-SSO-OSS
Services and demo applications use to test out FIDO2 passwordless authentication in [Keycloak](https://github.com/keycloak/keycloak) and [Apereo CAS](https://github.com/apereo/cas)

## Requirement
* [mkcert](https://github.com/FiloSottile/mkcert) - To make locally trusted development certificate for TLS/SSL. FIDO2 authentication method only works on HTTPS.
* [Docker](https://www.docker.com/) - Keycloak installation use Docker to deploy.
* [Java 11](https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html) - Apereo CAS latest stable release only supports Java 11.
* [Node.js](https://nodejs.org/en) - All my demo applications are SPAs that use either Node.js or Next.js to run.

## Preparation
You need to create a locally trusted certificate using mkcert. Follow their instruction and use the default installation so we have valid certificate for localhost. Notedown the location of where 

Go to `cas-rest`, `basic-auth-testapp`, `keycloak-rest`, `Website`, `Website/online-study-website` folders and run
```zsh
npm install
```
on each 

## Directories
Keycloak related folders are folders with names that started with `keycloak-*`. CAS folder starts with `cas-*`. Any other folder name are used by both services to test out single sign-on (SSO).

Due to using the same applications to test out both services, you cannot test both Keycloak and CAS at the same time. I also configure Keycloak and CAS to use the same local ports for configuration and communication. I recommend trying out Keycloak first before moving on to CAS.

## Keycloak
Testing out my implementation for FIDO2 passwordless authentication for Keycloak is simple. I have save a Keycloak setup with most configuration done into a Docker Image. You just have to simply download the image and run it on your own Docker.

Link to Docker Image: [https://drive.google.com/file/d/1GmxKnwF-9l13fP41ha2cBu-i04M0L23Q/view?usp=sharing](https://drive.google.com/file/d/1GmxKnwF-9l13fP41ha2cBu-i04M0L23Q/view?usp=sharing)

You can then use [docker load](https://docs.docker.com/engine/reference/commandline/load/) command to load the image into your Docker Local Image List:
```zsh
docker load < keycloak_custom.tar.gz
```

Then find the file `docker-compose.yaml` inside `keycloak-docker` folder. While inside the folder

Afterwards, use the file `docker-compose.yaml`