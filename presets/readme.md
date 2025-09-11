# Presets

TF module that creates default MediaConvert presets for Protagonist.

## Implementation

There is no native support for MediaConvert presets (see https://github.com/hashicorp/terraform-provider-aws/issues/11190) so this uses a `terraform-data` and `local-exec` to create them.

The expectation is that this will be a run-once operation and seldom change. 

## Use

To trigger a change, alter the `revision` variable. 

If there is a change to presets the default for this variable should be incremented. It is intentionally a string, rather than a number, to allow consumers to use a point number to force a reapply.

## Script

The python script will iterate through every json file in the `./templates` directory and:

* check if preset exists (`get-prest`)
* if it does exist, update preset (`update-preset`)
* else, create preset (`create-preset`)

> [!WARNING]
> This script has limitations.
> The expectation is that caller has `python` locally and boto3 installed.