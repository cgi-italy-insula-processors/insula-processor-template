# Insula processor template (cookiecutter)

Scaffold a new Insula EO processor repository with the layout the Insula build
pipeline expects.

## Requirements

- [cookiecutter](https://cookiecutter.readthedocs.io) (`pipx install cookiecutter`)

## Use

```
cookiecutter gh:cgi-italy-insula-processors/insula-processor-template
```

Answer the prompts (`processor_name`, `processor_slug`, `processor_description`,
`processor_version`, `keywords`). Cookiecutter creates a directory named after the
slug containing:

```
<processor_slug>/
├── README.md
├── code/
│   └── placeholder        # replace with your processor + a Dockerfile
└── <processor_slug>.cwl   # OGC Application Package (edit inputs/outputs)
```

## Base image constraint (read first)

The Dockerfile `FROM` MUST be a **public** image (Docker Hub, quay.io, ghcr.io, ...).
The build pipeline is public and cannot be given private-registry credentials, so a
private base image fails the build with a 401. This is the most common first-run
failure - decide your base image accordingly.

## Base image vulnerabilities (the scan gate)

The pipeline scans the built image with Grype and Trivy and BLOCKS publishing on
any HIGH/CRITICAL vulnerability - including ones that have no upstream fix yet.
In practice most findings come from the base image, not from your code. If your
build is blocked:

1. **Prefer a slim/minimal base.** `python:3.12-slim` instead of `python:3.12`,
   `debian:stable-slim` instead of `debian:stable`, alpine or distroless variants
   where your stack allows. Fewer packages, fewer findings.
2. **Rebuild on the newest patch tag** of that base: point releases regularly fix
   HIGH/CRITICAL CVEs that an older tag still carries.
3. **Keep build tooling out of the final image.** Compilers, curl/wget, dev
   headers all carry CVEs; use a multi-stage build and keep the runtime stage bare.
4. Still blocked by a genuinely unfixed base CVE after 1-3? There is no
   self-service override - contact a pipeline maintainer (a maintainer-only bypass
   exists for reviewed cases).

The run summary shows a Grype and a Trivy table (package, installed version,
version to upgrade to, CVE count) - work down from the top of those lists.

## Then

1. Add your processor code and a `Dockerfile` under `code/` (the pipeline builds
   `code/Dockerfile`; the `FROM` must obey the base image constraint above). Delete
   `code/placeholder`.
2. Edit `<processor_slug>.cwl` so its inputs/outputs match your processor. Leave
   `dockerPull: __IMAGE__` as is: the pipeline replaces it with the published image.
3. Create a PUBLIC GitHub repo under your own account, push this content.
4. **Get access first.** A maintainer must grant you access (add you to the launcher
   repo) before any build runs. `login` succeeds for ANY GitHub account, so it gives
   no signal here - but `create` fails at dispatch with a `404 Not Found` until you are
   onboarded. Ask a maintainer, then install the CLI and authenticate:
   ```
   pipx install git+https://github.com/cgi-italy-insula-processors/insula-processors-builder-cli
   insula-processors-builder login          # GitHub device flow, no token to create
   ```
   The login token expires after about 8 hours; re-run `login` when a build fails
   with an auth error (or set a fine-grained PAT via `INSULA_GITHUB_TOKEN` instead).
5. Build and deploy with the CLI:
   ```
   insula-processors-builder create --repo-url https://github.com/<you>/<processor_slug>
   ```
   The deploy step needs an Insula api token (generate at
   https://insula.earth/awareness/account/api_keys). Set `INSULA_API_TOKEN` in double
   quotes - without them the shell can break on special characters - or let the CLI
   prompt for it; a typed or pasted token is not shown in the terminal.
6. Iterate: push changes, run the command again.
7. If a maintainer had to force your build (a `--bypass` run), they hand you the
   published CWL release URL (the `create` output). Deploy it yourself, under your own
   api token, with no rebuild:
   ```
   insula-processors-builder deploy --cwl-url <release URL>
   ```

## CWL notes (what Insula supports)

- Exactly one `Workflow` and one `CommandLineTool` in `$graph`; the Workflow has a
  single step whose `run` points at the tool id.
- `DockerRequirement.dockerPull` is required. Keep the `__IMAGE__` token.
- Input types: `Directory` = a STAC catalogue input, `File` = a downloadable file,
  plus `string` / `int` / `long` / `float` / `boolean` / `enum`. Outputs must be
  `File` or `Directory`.
- Put each input's `label` and `doc` on the CommandLineTool input; that is where
  the platform reads the user-facing parameter metadata.
- `label` -> process title, `doc` -> description (kept under 255 chars),
  `s:softwareVersion` -> process version.
