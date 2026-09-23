cwlVersion: v1.2

# Insula Application Package (OGC API - Processes).
#
# Rules enforced by the platform:
#   - $graph must hold EXACTLY ONE Workflow and ONE CommandLineTool.
#   - The Workflow has a single step whose `run` points at the CommandLineTool id.
#   - DockerRequirement.dockerPull is REQUIRED and must stay the placeholder token
#     the build pipeline injects the published image reference into; do not edit that
#     line. Keep the token to exactly ONE occurrence (the dockerPull value below).
#   - Input types: Directory = a STAC catalogue, File = a downloadable file,
#     plus string / int / long / float / boolean / enum. Outputs must be
#     File or Directory. Type names are CASE-SENSITIVE: `String` is not `string`.
#   - The Workflow and the CommandLineTool must declare the SAME type for an input.
#   - The Workflow `doc` becomes the process description and is capped at 255
#     characters; a longer one makes the deploy fail.
#   - Put each input's label/doc on the CommandLineTool input (below): that is
#     where the platform reads the user-facing parameter metadata.
#   - FAN-OUT (one task per input product) is opt-in and all-or-nothing. It needs
#     `ScatterFeatureRequirement` in the WORKFLOW's requirements, `scatter` +
#     `scatterMethod: dotproduct` on the step, the scattered Workflow input as an
#     array, the CommandLineTool input as the single element, and EVERY Workflow
#     output as an array. The platform detects fan-out by that requirement alone,
#     so declaring one half without the other fails the deploy with a bare 500.
#     This scaffold is NOT a fan-out: leave all of it out unless you need it.
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
