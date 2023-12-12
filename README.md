#  FIDO-WebAuth-SSO-OSS
Services and demo applications use to test out FIDO2 passwordless authentication in [Keycloak](https://github.com/keycloak/keycloak) and [Apereo CAS](https://github.com/apereo/cas)

## Requirement
* [mkcert](https://github.com/FiloSottile/mkcert) - To make a locally trusted development certificate for TLS/SSL. The FIDO2 authentication method only works on HTTPS.
* [Docker](https://www.docker.com/) - Keycloak installation uses Docker to deploy.
* [Java 11](https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html) - Apereo CAS's latest stable release only supports Java 11.
* [Node.js](https://nodejs.org/en) - All my demo applications are SPAs that use either Node.js or Next.js to run.
* [Yarn](https://classic.yarnpkg.com/lang/en/docs/install) - All my applications are managed using yarn.

## Preparation
You need to create a locally trusted certificate using `mkcert`. Follow their instruction and use the default installation so we have a valid certificate for localhost. Note down the location of where 

Go to `cas-rest`, `keycloak-rest`, `basic-auth-testapp`, `Website`, `Website/online-study-website` folders and run
```zsh
yarn install
```
for each folder. This will download all the necessary libraries for those demo applications to run.

## Directories
Keycloak-related folders are folders with names that start with `keycloak-*`. CAS folder starts with `cas-*`. Any other folder names are used by both services to test out single sign-on (SSO).

Due to using the same applications to test out both services, you cannot test both Keycloak and CAS at the same time. I also configured Keycloak and CAS to use the same local ports for configuration and communication. I recommend trying out Keycloak first before moving on to CAS.

## Keycloak
Testing out my implementation for FIDO2 passwordless authentication for Keycloak is simple. I have saved a Keycloak setup with most configurations done into a Docker Image. You just have to simply download the image and run it on your own Docker.

Link to Keycloak Docker Image: https://drive.google.com/file/d/1GmxKnwF-9l13fP41ha2cBu-i04M0L23Q/view?usp=sharing

You can then use the [docker load](https://docs.docker.com/engine/reference/commandline/load/) command to load the image into your Docker Local Image List:
```zsh
docker load < keycloak_custom.tar.gz
```

Enter the folder `keycloak-docker/`, now either use `mkcert` to create your SSL certificate, or copy the two generated `*.pem` files you get from the ["Preparation"](#preparation) step into the `keycloak-docker/` folder. Rename those into `rootCA.pem` and `rootCA-key.pem` for the certificate file and the private key file for the certificate respectively.

Then find the file `docker-compose.yaml` inside the `keycloak-docker/` folder. Use it to instruct Docker Compose to run a new container from the downloaded image:
```zsh
docker compose -f ./docker-compose.yaml -p "keycloak_custom" up
```

Then with your Docker Desktop open, you should see a composed container with the name **"keycloak_custom"** running, with ports forwarded to `8080` and `8443` respectively. Navigate to https://localhost:8443 to see the Keycloak console.

### Credentials
The default credentials for the administrator account are:
```
Username: admin
Password: admin
```

I have also created a user account living on realms `passwordless` with credentials:
```
Username: test
Password: test
```

### Demo Applications
1. First navigate to `basic-auth-testapp/` and use the command:
```zsh
yarn https
```
2. Then with another terminal open, navigate to `keycloak-rest/`, and use this command:
```zsh
yarn https
```

This will serve as the first application used to test Keycloak SSO capabilities. Navigate to https://localhost:3000/keycloak to see the app.

Now click on the Sign-In button, and you should now be at the Keycloak login page. Use `test` for the username field and `test` for the following password field. Afterward, you should be prompted by Keycloak to register an authenticator to use for future FIDO2 passwordless authentication. After finishing registering your authenticator, the page should redirect you to another page.

Now delete all session cookies from your browser and go to https://localhost:3000/keycloak again. This time after the username field, you should see an option underneath the password field to "Use another method", after clicking on that, the passkey should be an option for the user to sign in.

3. Now navigate to folder `Websites/`, then use the command:
```zsh
yarn keycloak
```
4. With another terminal, use the command:
```zsh
yarn website
```

This will serve as our second application to see if Keycloak SSO works, since we have authenticated with the other app, Keycloak should have a session and our browser still has a session cookie that links to said session. Navigate to https://localhost:3002 and you should be automatically redirected to https://localhost:3003, making the SSO login successfully.

## Apereo Central Authentication System (CAS)
For CAS, you would have to do more configuration to get it up and running. Since CAS uses configuration files to change, there won't be a built-in interactive user interface for the user to look into. CAS uses WAR overlay as a way to deliver recommended pre-configured CAS software for developers.

I have included a WAR layer, with the necessary module extension to enable FIDO2 passwordless authentication in the folder `cas-waroverlay/`. You need to have Java 11 installed, as well as the `JAVA_HOME` system variables set and Java binary in the system PATH to execute the following steps.

1. Navigate to folder `cas-waroverlay/`.
2. Copy folder `etc/` to your root directory. CAS reads configuration files stored in the `etc/` directory but only from your current root directory.
3. Now run the commands:
```
./gradlew clean build
```
After finishing building, run the command:
```
./gradlew run
```

Now CAS should be up and running, navigate to https://localhost:8443/cas to access the login page of CAS.

### Credentials
The default built-in account that CAS uses is:
```
Username: casuser
Password: Mellon
```

### Demo Applications
1. Enter folder `cas-rest/` and then run the command:
```
yarn start
```
2. Navigate to https://localhost:8443/cas/login?authn_method=mfa-webauthn
3. Then log in using the above-mentioned credentials, afterward you will be asked to register your authenticator.
4. After this, either log out using the logout button or delete all session cookies from your browsers and close the browser.
5. Now enter folder `basic-auth-testapp/` and run the command:
```
yarn https
```
6. Now go to https://localhost:3000/cas on your browser. After clicking on "Login to CAS", you should be redirected to the CAS login page. Then click on the Login button under "Login with FIDO2-enabled Device". CAS now should be prompting you for a passkey.

6. Afterwards, navigate to folder `Website/` and then run the command:
```
yarn cas
```
Then on another terminal, run:
```
yarn website
```
7. Now that the second application is running, head to https://localhost:3003/cas. Since now that CAS has established a ticket-granting cookie for you with the previous application sign-in, you should be automatically redirected to https://localhost:3003, making the SSO login successful.