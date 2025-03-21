FROM registry.redhat.io/rhbk/keycloak-rhel9:26.0-8 as builder

# For optimized support https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/26.0/html/server_configuration_guide/containers-#containers-writing-your-optimized-red-hat-build-of-keycloak-containerfile
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_HTTPS_CLIENT_AUTH=request
ENV KC_HTTPS_MANAGEMENT_CLIENT_AUTH=request

ENV KEYCLOAK_HOME=/opt/keycloak
ARG KC_STORE_PASS=defaultpassword
ENV KC_STORE_PASS=${KC_STORE_PASS}
ARG KC_KEY_PASS=defaultpassword
ENV KC_KEY_PASS=${KC_KEY_PASS}
WORKDIR /opt/keycloak

# Downloading the non-RH owned BCFIPS .jar dependencies
# See https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/26.0/html/server_configuration_guide/fips-#fips-bouncycastle-fips-bits
RUN mkdir -p $KEYCLOAK_HOME/providers
ADD --chown=keycloak:keycloak --chmod=644 https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar $KEYCLOAK_HOME/providers/bc-fips-2.0.0.jar
ADD --chown=keycloak:keycloak --chmod=644 https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar $KEYCLOAK_HOME/providers/bctls-fips-2.0.19.jar
ADD --chown=keycloak:keycloak --chmod=644 https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar $KEYCLOAK_HOME/providers/bcpkix-fips-2.0.7.jar
ADD --chown=keycloak:keycloak --chmod=644 https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar $KEYCLOAK_HOME/providers/bcutil-fips-2.0.3.jar

# Create the security profile setting for generating the keystore
RUN echo 'securerandom.strongAlgorithms=PKCS11:SunPKCS11-NSS-FIPS' > /tmp/kc.keystore-create.java.security
# Generate keystore
RUN mkdir -p $KEYCLOAK_HOME/conf
RUN keytool -keystore $KEYCLOAK_HOME/conf/server.keystore \
  -storetype bcfks \
  -providername BCFIPS \
  -providerclass org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
  -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
  -providerpath $KEYCLOAK_HOME/providers/bc-fips-*.jar \
  -alias localhost \
  -dname 'CN=localhost' \
  -genkeypair -sigalg SHA512withRSA -keyalg RSA -storepass ${KC_STORE_PASS} \
  -keypass ${KC_KEY_PASS} \
  -J-Djava.security.properties=/tmp/kc.keystore-create.java.security

# Not needed according to https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/26.0/html/server_configuration_guide/fips-#fips-red-hat-build-of-keycloak-server-in-fips-mode-in-containers
# "Security file kc.java.security with added provider for SAML (Not needed with OpenJDK 21 or newer OpenJDK 17)"
# RUN cp /tmp/files/kc.java.security /opt/keycloak/conf/ 

# Builds FIPS compatible keycloak
RUN /opt/keycloak/bin/kc.sh build --features=fips --fips-mode=strict


# Final mile copy into clean layer
FROM registry.redhat.io/rhbk/keycloak-rhel9:26.0-8
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
