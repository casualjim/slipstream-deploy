This directory contains example OpenTofu variable files used by the repository's mise task wrapper.

Usage

- Default var-file lookup pattern: `tofu/infra/vars/{provider}-{environment}.tfvars`.
- To run a plan using the default file for OVH/dev:

```
mise tofu:plan --provider ovh --environment dev
```

- To pass a custom var-file path:

```
mise tofu:plan --provider ovh --environment dev --vars-file path/to/custom.tfvars
```

Notes

- Variable files are plain Terraform `key = value` assignments and are passed to OpenTofu with `-var-file`.
- Keep secrets out of these files; use `tofu/infra/secrets/*.yaml` (SOPS) for sensitive values as documented.
