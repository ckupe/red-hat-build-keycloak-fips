#!/bin/env bash

if [[ -z "${KC_STORE_PASS}" ]]; then
  echo 'No Keycloak Keystore Password has been defined. Exiting.' && exit
fi

# export KC_STORE_PASS in github actions or locally
podman build -t ghcr.io/ckupe/rhbk-fips:latest -f Containerfile --build-arg KC_STORE_PASS=$KC_STORE_PASS --build-arg KC_KEY_PASS=$KC_KEY_PASS
