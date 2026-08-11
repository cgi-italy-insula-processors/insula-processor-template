# Insula processor template (cookiecutter)

Scaffold a new Insula EO processor repository with the layout the Insula build
pipeline expects.

## Requirements

- Python 3.11+ and [pipx](https://pipx.pypa.io). No pipx yet? Follow the
  [Windows and Linux install guide](https://github.com/cgi-italy-insula-processors/insula-processors-builder-cli#prerequisites-python-311-and-pipx).
- [cookiecutter](https://cookiecutter.readthedocs.io): `pipx install cookiecutter`

## Use

```
cookiecutter gh:cgi-italy-insula-processors/insula-processor-template
```

Cookiecutter asks five questions, then creates a directory named after the slug:

```
<processor_slug>/
├── README.md
├── code/
│   └── placeholder        # replace with your processor + a Dockerfile
└── <processor_slug>.cwl   # OGC Application Package (edit inputs/outputs)
```

### The five parameters

| Prompt | Example answer | What it becomes |
|--------|----------------|-----------------|
| `processor_name` | `Daily Evapotranspiration` | Human-readable title. Goes into the CWL Workflow `label`, which Insula shows as the process title, and into the scaffolded README heading. Free text, spaces and capitals welcome. |
| `processor_slug` | `daily-evapotranspiration` | The machine-readable name (see below). Becomes the created directory name, the `<processor_slug>.cwl` file name, and the CWL Workflow `id`. |
| `processor_description` | `Estimates daily evapotranspiration from Sentinel-2 and Sentinel-3 acquisitions.` | The CWL Workflow `doc`, shown by Insula as the process description. One line, keep it under 255 characters (Insula truncates beyond that). |
| `processor_version` | `1.0.0` | The CWL `s:softwareVersion`, shown as the process version. Use semantic versioning (`major.minor.patch`) and raise it when you publish a changed processor. |
| `keywords` | `earth-observation, evapotranspiration, sentinel-2` | The CWL `s:keywords`. A comma-separated list used for search and categorization. |

### processor_slug: it must be a valid slug

A slug is a string safe to use in URLs, file names, folder names, and identifiers.
Cookiecutter proposes one derived from `processor_name` (lowercased, spaces and
underscores turned into hyphens); press Enter to accept it, or type your own
respecting these rules:

- lowercase letters `a-z`, digits `0-9`, and hyphens `-` only
- starts with a letter or a digit
- no spaces, no accented or non-ASCII characters, no `_`, `.`, `/`, `\`, `:` or any
  other punctuation

| Answer | Verdict |
|--------|---------|
| `daily-evapotranspiration` | valid |
| `s3-eutrophication-monitor` | valid |
| `Daily Evapotranspiration` | invalid - capitals and spaces |
| `daily_evapotranspiration` | invalid - underscore |
| `evapotraspirazione-giornaliera-v1.0` | invalid - dot |

Name your GitHub repository after the slug too. The pipeline derives the published
container image name from the repository (`<owner>-<repo>`, lowercased) and rejects
anything outside `^[a-z0-9][a-z0-9._-]*$`, so a slug-shaped repository name keeps the
image name predictable.

### Example run

```
$ cookiecutter gh:cgi-italy-insula-processors/insula-processor-template
  [1/5] processor_name (My EO Processor): Daily Evapotranspiration
  [2/5] processor_slug (daily-evapotranspiration):
  [3/5] processor_description (Short description of what this processor does): Estimates daily evapotranspiration from Sentinel-2 and Sentinel-3 acquisitions.
  [4/5] processor_version (1.0.0): 1.0.0
  [5/5] keywords (earth-observation, processing): earth-observation, evapotranspiration, sentinel-2

$ ls daily-evapotranspiration
README.md  code/  daily-evapotranspiration.cwl
```

Prompt 2 shows the slug derived from your answer to prompt 1; Enter accepts it.

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
5. Store your Insula api token once (needed by the deploy step; generate it at
   https://insula.earth/awareness/account/api_keys). The command asks for it without
   echoing it, so the token never goes through your shell:
   ```
   insula-processors-builder set-api-token
   ```
6. Build and deploy with the CLI:
   ```
   insula-processors-builder create --repo-url https://github.com/<you>/<processor_slug>
   ```
7. Iterate: push changes, run the command again.
8. If a maintainer had to force your build (a `--bypass` run), they hand you the
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
