# {{cookiecutter.processor_name}}

EO data processor packaged as a Docker image, built and published through the
Insula processor pipeline.

## Structure

- `code/` - your processor. Must contain a `Dockerfile` that builds the image.
- `{{cookiecutter.processor_slug}}.cwl` - the OGC Application Package describing the
  process (inputs, outputs, command). The `dockerPull` value `__IMAGE__` is filled
  in automatically at build time; do not edit it.

## Editing the CWL: caveats

Insula rejects a malformed Application Package with an HTTP 400 that carries no
explanation, at the END of the pipeline - after the image was built, scanned and
published. Check yours locally first; it takes seconds:

```
insula-processors-builder validate --cwl {{cookiecutter.processor_slug}}.cwl
```

`create` runs the same checks on the repository before dispatching a build. The
mistakes they catch, most common first:

- the Workflow `doc` longer than **255 characters** (it is the process description,
  and the platform caps it)
- a type spelled with the wrong case: it is `string`, `int`, `long`, `float`,
  `double`, `boolean`, `File`, `Directory`. `String` is not a CWL type
- the Workflow and the CommandLineTool declaring different types for the same input
- an input or output present on one side only (Workflow, step `in`/`out`, tool)
- an output typed as anything but `File` or `Directory`
- a requirement outside `DockerRequirement`, `ResourceRequirement`, `NetworkAccess`,
  `EnvVarRequirement`, `InitialWorkDirRequirement`
- the `__IMAGE__` token edited, removed or duplicated

Two things the checks CANNOT catch: `baseCommand` still set to the template
placeholder instead of your real entrypoint (it fails at run time), and anything
that depends on platform state, such as a process name already in use.

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
https://insula.earth/awareness/account/api_keys). Store it once with
`insula-processors-builder set-api-token`: the command asks for the token without
echoing it, so the value never passes through your shell.

The pipeline clones this repo, builds `code/Dockerfile`, scans and publishes the
image, injects the published image reference into the CWL, and deploys the process
to Insula. Iterate by pushing changes and running the command again.
