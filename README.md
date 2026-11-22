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
| `traefik_acme_email` | `""` | ACME account address and the opt-in switch for certificate automation: while it is empty no `certificatesResolvers` section is rendered. The rendered resolver is named `letsencrypt`. |
| `traefik_acme_ca_server` | `https://acme-v02.api.letsencrypt.org/directory` | ACME CA directory URL. Use `https://acme-staging-v02.api.letsencrypt.org/directory` to prove issuance and renewal without burning production rate limits. |
| `traefik_acme_storage` | `{{ traefik_data_dir }}/acme.json` | LEGO account and certificate store. The role creates it `0600` owned by `traefik_user` before the first start; it holds private keys and must never be world-readable. |
| `traefik_acme_dns_provider` | `""` | DNS-01 challenge provider for the resolver (e.g. `route53`). Empty means Traefik's default HTTP-01 challenge. |
| `traefik_acme_dns_delay` | `""` | `delayBeforeCheck` duration (e.g. `30s`) before Traefik starts checking DNS propagation. |
| `traefik_acme_dns_resolvers` | `[]` | Custom DNS servers (`host:port`) used for the propagation check. |
| `traefik_acme_dns_disable_propagation_check` | `false` | Skip the DNS propagation check (lego's own timeout still applies). |
| `traefik_env_file` | `""` | Environment file sourced by the systemd unit. Empty means no `EnvironmentFile` line, except that a configured `traefik_acme_dns_provider` defaults it to `{{ traefik_config_dir }}/env`. |
| `traefik_enable_file_provider` | `false` | Opt-in for Traefik's file provider: renders a watched `providers.file` section and deploys dynamic fragments. |
| `traefik_dynamic_config_dir` | `/etc/traefik/dynamic` | Watched directory for the fragments (deployed `0750`, group-readable by `traefik_group`; fragments are `0640`). |
| `traefik_dynamic_configs` | `{}` | Dict of fragment file name to Traefik dynamic configuration structure; rendered as YAML, and names dropped from the dict are deleted from the directory. |
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

TLS certificates (ACME)
-----------------------

Traefik can automate certificates through an ACME CA, but the role does not
configure one until you ask: while `traefik_acme_email` is empty (the default)
no `certificatesResolvers` section is rendered, exactly as before the option
existed. Set the email and the role renders a resolver named **`letsencrypt`**
(routers reference it as `certResolver: letsencrypt`) and creates the
`acme.json` store `0600` owned by the service user before the first start.

For public hostnames the HTTP-01 challenge is often blocked; a DNS-01 resolver
proves control of the zone instead. lego — the ACME library inside Traefik —
reads DNS provider credentials from the **environment**, so the unit gains an
optional `EnvironmentFile` line: setting `traefik_acme_dns_provider` defaults
it to `/etc/traefik/env` (override with `traefik_env_file`), and the file
itself is yours to manage — vault, `copy` task, whatever — the role never
writes it, and the leading `-` in the unit means Traefik starts even before
the file exists. The static configuration stays world-readable and secret
free.

    - hosts: servers
      roles:
        - role: carlosroman.traefik
          vars:
            traefik_enable_https: true
            traefik_acme_email: certs@example.com
            # Prove issuance against staging before switching back to the
            # production default:
            traefik_acme_ca_server: https://acme-staging-v02.api.letsencrypt.org/directory
            traefik_acme_dns_provider: route53
            traefik_acme_dns_delay: 30s

    # The credentials themselves live outside Ansible-managed config files:
    # /etc/traefik/env holds AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and
    # AWS_REGION for the route53 provider.

Failing to issue (bad credentials, unreachable CA) is a logged error, not a
stopped proxy: Traefik keeps serving the entry points that do not need the
missing certificate. `make test/acme` covers the rendering, the unit wiring,
the `acme.json` permissions and that survival.

Dynamic routers (file provider)
-------------------------------

Routers and services belong to Traefik's *dynamic* configuration. Set
`traefik_enable_file_provider: true` and the role renders a watched
`providers.file` section pointing at `traefik_dynamic_config_dir` (deployed
`0750`, group-readable by the service group) and deploys each entry of
`traefik_dynamic_configs` — a dict of fragment file name to the dynamic
configuration structure itself — as YAML into that directory. Names removed
from the dict are deleted again, so a router retired in inventory disappears
on the next converge.

    - hosts: servers
      roles:
        - role: carlosroman.traefik
          vars:
            traefik_enable_https: true
            traefik_acme_email: certs@example.com
            traefik_acme_dns_provider: route53
            traefik_enable_file_provider: true
            traefik_dynamic_configs:
              jellyfin.yml:
                http:
                  routers:
                    jellyfin:
                      rule: "Host(`media.example.com`)"
                      entryPoints:
                        - websecure
                      service: jellyfin
                      tls:
                        certResolver: letsencrypt
                  services:
                    jellyfin:
                      loadBalancer:
                        servers:
                          - url: http://127.0.0.1:8096

Traefik v2 removed v1's `traefik validate` command, so the role pre-activates
with a startup probe instead: after every configuration change it boots
copies of the rendered files — every entry point on an ephemeral port, a
throwaway ACME store, so the probe can never disturb the running service or
its keys — for a few seconds, and treats anything the real binary logs as an
error (unknown fields, dangling service references, a router naming a
certificate resolver that does not exist) as a failed change. The play fails
before the restart handler runs, so a rejected configuration never
activates. As belt-and-braces the file provider itself is fail-safe: a
malformed fragment appearing later is rejected in favour of the last good
configuration. `make test/acme` asserts the fragments deploy, the routers
actually serve, and the probe rejects a bad fragment.

## License

MIT

## Author Information

Carlos Roman ([@carlosroman](https://github.com/carlosroman)), Cliche Solutions Ltd
