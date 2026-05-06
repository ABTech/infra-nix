# abtech NixOS IaC Demo

Demo: nix-demo.abtech.org

## Structure

- `hosts/` - minimal configuration specific to each host
- `pkgs/` - custom package definitions (e.g. if missing upstream)
- `profiles/` - configuration common to machines
- `secrets/` - secrets keyed to specific machines
- `services/` - configuration for a specific application
- `admins.nix` - administrator list and packages
- `flake.nix` - top-level object with machine, devshell, deployment definitions
- `flake.lock` - dependency lockfile

## Deployment

Create a temporary shell with deployment dependencies.

```
nix develop
```

Then, deploy to all hosts.

```
deploy . \
  --skip-checks \     # Skip static reachability checks. Needed on MacOS/arm64.
  --remote-build \    # Build closure on remote machine. Needed on MacOS/arm64.
  --interactive-sudo  # Authenticate remote sudo with (krb5) password
```

If you're on a linux-amd64 machine, omit `--skip-checks` to run additional build-time checks that the machine is likely to be reachable and boot correctly after deploy. However, an unreachable machine will automatically rollback after deploy regardless.

Machine users have sudo authenticated via krb5. As authorization to deploy arbitrary images is equivalent to full machine control, I don't add NOPASSWD exceptions for deployment scripts. Instead, a user must provide a sudo password in addition to authenticating to the machine.

See `deploy --help` for more options. Notably: `-i` interactive mode and `--targets` target filter.

## Secrets

Machine secrets are encrypted at rest with age. Administrator keys should be added to `secrets.nix`, and `update-masterkeys` run by an already-bootstrapped admin.

Secrets that are defined internally may be initialized with generators instead of manually entered. After writing a definition, run `agenix generate`. They can be viewed by administrators with `agenix view`.

Secrets that originate externally can be written with `agenix edit`.

After a secret is updated, an administrator must rewrite the appropriate host secrets with `agenix rekey -a`.




