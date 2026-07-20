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

## Then

1. Add your processor code and a `Dockerfile` under `code/` (the pipeline builds
   `code/Dockerfile`). Delete `code/placeholder`.
2. Edit `<processor_slug>.cwl` so its inputs/outputs match your processor. Leave
   `dockerPull: __IMAGE__` as is: the pipeline replaces it with the published image.
3. Create a PUBLIC GitHub repo under your own account, push this content.
4. Build and deploy with the CLI:
   ```
   insula-processor create --repo-url https://github.com/<you>/<processor_slug>
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
