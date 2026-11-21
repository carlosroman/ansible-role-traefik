# Ansible Role: Traefik

[![CI](https://github.com/carlosroman/ansible-role-traefik/actions/workflows/ci.yml/badge.svg)](https://github.com/carlosroman/ansible-role-traefik/actions/workflows/ci.yml)

Installs and configures [Traefik](https://traefik.io/traefik/), the modern HTTP
reverse proxy and load balancer. The Traefik binary is downloaded from the
[official GitHub releases](https://github.com/traefik/traefik/releases) and
verified against the published SHA256 checksums. The role manages a dedicated
service user, the static configuration file, and a systemd unit.

## Requirements

None. The target must be able to reach `github.com` and `api.github.com` to
download the release archive and checksums. When `traefik_version` is empty the
latest release is resolved via the GitHub API, which is rate-limited for
unauthenticated requests — pin `traefik_version` to avoid API failures.

## Role Variables

Available variables are listed below, along with their default values (see `defaults/main.yml`).

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_version` | `""` | Version to install (e.g. `v3.7.19`). Empty means the latest release, resolved via the GitHub API. |
| `traefik_github_owner` | `traefik` | GitHub owner of the release binaries. |
| `traefik_github_repo` | `traefik` | GitHub repository of the release binaries. |
| `traefik_install_dir` | `/usr/local/bin` | Directory the `traefik` binary is installed into. |
| `traefik_config_dir` | `/etc/traefik` | Directory holding the static configuration file. |
| `traefik_data_dir` | `/var/lib/traefik` | Writable directory for Traefik data (e.g. `acme.json`). |
| `traefik_user` | `traefik` | Service user running Traefik. |
| `traefik_group` | `traefik` | Service group running Traefik. |
| `traefik_service_name` | `traefik` | Name of the systemd service managed by this role. |
| `traefik_http_port` | `80` | Port of the `web` (HTTP) entrypoint. |
| `traefik_enable_https` | `false` | Whether to enable the `websecure` (HTTPS) entrypoint. |
| `traefik_https_port` | `443` | Port of the `websecure` entrypoint. |
| `traefik_enable_dashboard` | `false` | Whether to enable the `traefik` entrypoint and the dashboard/API. |
| `traefik_dashboard_port` | `8080` | Port of the `traefik` (dashboard/API) entrypoint. |
| `traefik_config_extras` | `{}` | Extra YAML structure merged into the static configuration file (top-level Traefik options). |

## Dependencies

None.

## Example Playbook

    - hosts: servers
      roles:
        - role: carlosroman.traefik

Enable the HTTPS entrypoint and the dashboard:

    - hosts: servers
      roles:
        - role: carlosroman.traefik
          vars:
            traefik_version: v3.7.19
            traefik_enable_https: true
            traefik_enable_dashboard: true

## License

MIT

## Author Information

Carlos Roman ([@carlosroman](https://github.com/carlosroman)), Cliche Solutions Ltd
