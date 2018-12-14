# Changelog

## 0.1.9 - Dec 14 2018
- Sort files by name before rendering ERB. That allows you to add files like `_globals/variables.tf` with some custom ruby code that will run before parsing anything else.
- Fix bug with exception handling

## 0.1.8 - Dec 5 2018
- Set environment variable TFLAT_WORKSPACE to have the `.tflat` folder have a suffix. Useful for running same code on different states, for example.


## 0.1.7 - Nov 18 2018
- Environment variables `TF_VAR_*` are also loaded by Ruby and will overwrite a value set in the JSON file.

## 0.1.6 - Nov 17 2018
- Folders or files with the character '#' on their names will be ignored. You can use that to comment several files at once by commenting their folder.

## 0.1.5 - Nov 17 2018
- More verbose output to make it easier to catch ERB errors.

## 0.1.4 - Skipped

## 0.1.3 - Nov 12 2018
- Added helper method `file_sha256(file)` to return the SHA256 of `file`'s content. This is useful for `null_resource` triggers.
- Fixed bug when file gets loaded before ERB parsed when using the `file` helper
## 0.1.2 - Nov 11 2018
- Variables listed in JSON format inside file `terraform.tfvars.json` are accessible in rendered ERB as a HASH named `@variables` (with string keys).
