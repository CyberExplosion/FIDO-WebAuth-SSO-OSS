FROM keycloak/keycloak:latest

# Set environment variable
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin

# Expose port for application to listen on
EXPOSE 8080

# Set the custom entry point
CMD [ "start-dev" ]