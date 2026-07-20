# {{cookiecutter.processor_name}}

EO data processor packaged as a Docker image, built and published through the
Insula processor pipeline.

## Structure

- `code/` - your processor. Must contain a `Dockerfile` that builds the image.
- `{{cookiecutter.processor_slug}}.cwl` - the OGC Application Package describing the
  process (inputs, outputs, command). The `dockerPull` value `__IMAGE__` is filled
  in automatically at build time; do not edit it.

## Build and deploy

This repository has no CI of its own. Build and deploy it with the
insula-processors-builder CLI (the repo must be public):

```
insula-processors-builder create --repo-url https://github.com/<you>/{{cookiecutter.processor_slug}}
```

The pipeline clones this repo, builds `code/Dockerfile`, scans and publishes the
image, injects the published image reference into the CWL, and deploys the process
to Insula. Iterate by pushing changes and running the command again.
