cwlVersion: v1.2

# Insula Application Package (OGC API - Processes).
#
# Rules enforced by the platform:
#   - $graph must hold EXACTLY ONE Workflow and ONE CommandLineTool.
#   - The Workflow has a single step whose `run` points at the CommandLineTool id.
#   - DockerRequirement.dockerPull is REQUIRED. The value __IMAGE__ is replaced by
#     the build pipeline with the published image reference; do not edit it.
#   - Input types: Directory = a STAC catalogue, File = a downloadable file,
#     plus string / int / long / float / boolean / enum. Outputs must be
#     File or Directory.
#   - Put each input's label/doc on the CommandLineTool input (below): that is
#     where the platform reads the user-facing parameter metadata.
#
# Replace the single example `input` / `output` with the real parameters of your
# processor, keeping the Workflow and CommandLineTool sides in sync.
$graph:
- class: Workflow
  id: {{cookiecutter.processor_slug}}
  label: {{cookiecutter.processor_name}}
  doc: {{cookiecutter.processor_description}}
  inputs:
    input:
      label: Input catalogue
      doc: STAC catalogue of the products to process
      type: Directory
  outputs:
    output:
      type: Directory
      outputSource: process/output
  steps:
    process:
      run: '#main'
      in:
        input: input
      out:
        - output

- class: CommandLineTool
  id: main
  requirements:
    DockerRequirement:
      dockerPull: __IMAGE__
    # Runtime network egress is OFF by default. Set to true ONLY if your processor
    # must reach the network while it runs (most batch EO processors do not).
    NetworkAccess:
      networkAccess: false
  # PLACEHOLDER - replace with the exact ENTRYPOINT/command your Dockerfile runs.
  baseCommand: /home/worker/processor/workflow.sh
  inputs:
    input:
      label: Input catalogue
      doc: STAC catalogue of the products to process
      type: Directory
      inputBinding:
        position: 1
        prefix: --input
  outputs:
    output:
      type: Directory
      outputBinding:
        glob: ./outDir/output/

$namespaces:
  s: https://schema.org/
s:softwareVersion: {{cookiecutter.processor_version}}
s:keywords: {{cookiecutter.keywords}}
$schemas:
- http://schema.org/version/latest/schemaorg-current-http.rdf
