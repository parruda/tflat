# Changelog

## 0.1.4 - Nov 17 2018
- More verbose output to make it easier to catch ERB errors.

## 0.1.3 - Nov 12 2018
- Added helper method `file_sha256(file)` to return the SHA256 of `file`'s content. This is useful for `null_resource` triggers.
- Fixed bug when file gets loaded before ERB parsed when using the `file` helper
## 0.1.2 - Nov 11 2018
- Variables listed in JSON format inside file `terraform.tfvars.json` are accessible in rendered ERB as a HASH named `@variables` (with string keys).
