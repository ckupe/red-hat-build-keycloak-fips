# FIPS Red Hat Build of Keycloak

This opinionated configuration of Red Hat Build of Keycloak uses a FIPS 140-2 compliant build, utilizing CloudNativePG for highly available clustered PostgreSQL for a proper 3-node DB, 3-node keycloak instance SSO service. This is mainly targeting Red Hat Openshift.

# Install

If disconnected:

- Mirror the image (`ghcr.io/ckupe/rhbk-fips:latest`) into your mirror registry with oc-mirror, and configure ImageContentSourcePolicy manifests in the openshift-marketplace namespace.

Finally:

- `oc create namespace rhbk`
- Install CloudNativePG Operator from console
- Install Red Hat Keycloak Operator from console
- `oc create -f cluster.yml` and let the 3-node postgres database cluster provision and reconcile. once all 3 pods are Ready, proceed.
- edit keycloak.yml and set your desired ingress route hostname (https://...)
- create a TLS secret named `ingress-tls` in the namespace for keycloak to be able to use as the SSL cert. you can steal the default ingress router cert from `openshift-ingress`
- `oc create -f keycloak.yml` and let the 3-node keycloak cluster provision. check it successfully connects to postgres via pod logs


# Initial Admin

- Grab the init-admin credential
```
oc get secret keycloak-initial-admin -o json | jq -r '.data.password' | base64 -d
```

- Login to your instance with your route
  - username is `temp-admin`
```
oc get -n rhbk routes
```
