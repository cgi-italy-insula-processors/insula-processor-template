# {{cookiecutter.processor_name}}

EO data processor packaged as a Docker image, built and published through the
Insula processor pipeline.

## Structure

- `code/` - your processor. Must contain a `Dockerfile` that builds the image.
- `{{cookiecutter.processor_slug}}.cwl` - the OGC Application Package describing the
  process (inputs, outputs, command). The `dockerPull` value `__IMAGE__` is filled
  in automatically at build time; do not edit it.

## Base image constraint (important)

The Dockerfile `FROM` must be a **public** image (Docker Hub, quay.io, ghcr.io, ...).
The build pipeline is public and cannot receive private-registry credentials, so a
private base image fails at build time with a 401.

## Security scan gate

The pipeline scans the built image (Grype + Trivy) and blocks publishing on
HIGH/CRITICAL vulnerabilities, including unfixed ones - most come from the base
image. Prefer a slim, freshly patched base (`-slim`, alpine, distroless), rebuild
on its newest patch tag, and keep build tools out of the final stage (multi-stage
build). If a genuinely unfixable base CVE still blocks you, contact a pipeline
maintainer.

## Build and deploy

This repository has no CI of its own. Build and deploy it with the
insula-processors-builder CLI (the repo must be public):

```
insula-processors-builder create --repo-url https://github.com/<you>/{{cookiecutter.processor_slug}}
```

Deploying needs an Insula api token (generate at
https://insula.earth/awareness/account/api_keys): set `INSULA_API_TOKEN` in double
quotes - without them the shell can break on special characters - or let the CLI
prompt for it (a typed or pasted token is not shown in the terminal).

The pipeline clones this repo, builds `code/Dockerfile`, scans and publishes the
image, injects the published image reference into the CWL, and deploys the process
to Insula. Iterate by pushing changes and running the command again.
