---
#SPDX-License-Identifier: MIT-0
name: convert-base-role
description: Use when asked to convert, adapt, or turn this base Ansible role into a role for a specific target (software, service, or application), e.g. "convert this role into a Traefik role". Covers renaming, metadata, README, defaults, tasks, molecule, and validation.
---

# Skill: Convert Base Role

## Required Inputs

Before implementing, gather the following from the user. This skill is target-agnostic and
must not assume or research sources on its own — if any item is missing, ask the user
before writing tasks that depend on it:

| Input | Needed for | Example question |
|-------|-----------|------------------|
| Install method | `tasks/setup-*.yml` | OS package, upstream repo, static binary, or container? |
| APT repo URL + GPG key source | `setup-Debian.yml` | Which APT repository URI and signing key should be used? |
| RPM repo URL + GPG key | `setup-RedHat.yml` | Which `baseurl` and `gpgkey` should be used? |
| Binary source + checksum | `setup-*.yml` | Where are the binaries published (e.g., GitHub releases page, download site) and how are they verified (checksums, signatures)? Pin which version? |
| Container image + tag | container tasks | Which image and tag should be used? |
| Service ports | defaults, molecule verify | Which ports does the service listen on? |
| Config file locations | templates, handlers | Where do config and data live (`/etc/...`, `/var/lib/...`)? |
| Service name and user | handlers, systemd | What systemd unit and service user does it use? |
| systemd unit source | `templates/`, `setup-*.yml` | Does the package/binary ship its own systemd unit, or must the role install one? |

Only the inputs matching the chosen install method apply — for a static binary install,
ask for the binary source instead of APT/RPM repos, and vice versa. When installing
binaries, always download with an explicit version and verify the checksum or signature
(`ansible.builtin.get_url` with `checksum`). Binary archives often do not include a
systemd unit: check whether the archive or upstream repo ships one, and if not, the role
must create it (see workflow step 7).

If the user provides upstream documentation links instead, extract the facts above and
confirm them back before implementing. Never invent repository URLs, key fingerprints, or
package names.

## Naming Conventions

Derive these names from the target and reuse them everywhere:

| Name | Rule | Example (Traefik) |
|------|------|-------------------|
| `role_name` | Lowercase, underscores | `traefik` |
| Galaxy name | `<namespace>.<role_name>` | `carlosroman.traefik` |
| Repo name | `ansible-role-<role_name>` | `ansible-role-traefik` |
| Variable prefix | `<role_name>_` | `traefik_port` |

## Workflow

1. **Identify the target and gather inputs.** Collect everything in **Required Inputs**
   above; ask the user for anything missing. If the target is ambiguous (e.g., acronym,
   multiple editions), confirm which one.
2. **Rename the repository** (on GitHub and locally) to `ansible-role-<role_name>` and
   update the `origin` remote if needed.
3. **Update `meta/main.yml`:**
   - `galaxy_info.role_name`
   - `galaxy_info.description` (e.g., `Role used to install <Target>`)
   - `galaxy_info.galaxy_tags` (target name plus relevant tags, all lowercase)
   - Leave `namespace`, `author`, `company`, `license`, `min_ansible_version` as-is.
4. **Replace `README.md`** using the template below. Fill in sections with real content;
   keep clearly-labeled placeholders only for features not implemented yet.
5. **Define variables in `defaults/main.yml`** with the `<role_name>_` prefix and a comment
   for each one.
6. **Implement tasks:**
   - Keep `tasks/main.yml` as the orchestrator with
     `ansible.builtin.include_tasks: setup-{{ ansible_facts.os_family }}.yml`.
   - Put OS-specific work in `tasks/setup-Debian.yml` and `tasks/setup-RedHat.yml`,
     replacing the placeholder debug tasks.
   - Follow `CONVENTIONS-DEBIAN.md` for APT repositories (`deb822_repository`) and
     `CONVENTIONS-REDHAT.md` for YUM/DNF repositories (`yum_repository`).
7. **Add `handlers/`** for service restart/reload triggered by config changes, and config
   templates under `templates/` (owner/group/mode set explicitly).
8. **Add a systemd unit if needed.** Determine whether the service is already managed by a
   unit that comes from the package or upstream archive. If the role must provide it:
   - Template `templates/<role_name>.service` (set `ExecStart`, `User`/`Group`,
     `Restart`, and hardening options; reference role variables, not hardcoded paths).
   - Install it to `/etc/systemd/system/<role_name>.service` with
     `ansible.builtin.template`, then `daemon_reload: true`.
   - Enable and start it with `ansible.builtin.systemd_service` (`enabled: true`,
     `state: started`).
   - If a unit already ships with the package, skip the template and only
     enable/start/manage the existing unit.
9. **Update `molecule/default/converge.yml`:**
   - The `roles:` entry must use the new Galaxy name.
   - Replace the placeholder verify post-task with real idempotent verification
     (service running, port listening, config valid).
   - When the role provides a systemd unit, verify it explicitly: assert the unit file
     exists, the service is `enabled`, and `systemctl is-active` reports `active`
     (e.g., `ansible.builtin.systemd_service` registered with `changed_when: false`).
     The molecule containers run privileged with cgroup support, so systemd works.
10. **Clean up placeholders.** Remove any remaining `my_role` debug tasks and base-role text.
11. **Validate:**

    ```bash
    make setup
    make lint
    make test
    ```

12. **Commit as you go.** Commit each completed step (steps 2–9) separately with the
    conventional-commits skill (see `.agents/skills/conventional-commits/SKILL.md`)
    rather than one commit at the end. Each commit must pass `make lint` on its own;
    run `make test` once at the end (step 11) and commit any fixes as follow-up commits.
    Typical breakdown:

    - `template(meta): rename role to <role_name> for <Target>` (steps 2–3)
    - `docs(readme): convert base role readme to <Target> role` (step 4)
    - `feat(defaults): add <Target> role variables` (step 5)
    - `feat(tasks): implement <Target> installation and configuration` (steps 6–7)
    - `feat(tasks): add <Target> systemd unit` (step 8, binary installs)
    - `test(molecule): verify <Target> role` (step 9)

## README Template

Replace the entire contents of `README.md` with this, substituting `<Target>`,
`<role_name>`, and `<description>`:

```markdown
# Ansible Role: <Target>

[![CI](https://github.com/carlosroman/ansible-role-<role_name>/actions/workflows/ci.yml/badge.svg)](https://github.com/carlosroman/ansible-role-<role_name>/actions/workflows/ci.yml)

<One or two sentences describing what the role installs and configures, with a link to the
target project.>

## Requirements

None.

## Role Variables

Available variables are listed below, along with their default values (see `defaults/main.yml`).

| Variable | Default | Description |
|----------|---------|-------------|
| `<role_name>_example` | `value` | ... |

## Dependencies

None.

## Example Playbook

    - hosts: servers
      roles:
        - role: carlosroman.<role_name>

## License

MIT

## Author Information

Carlos Roman ([@carlosroman](https://github.com/carlosroman)), Cliche Solutions Ltd
```

Notes:

- List every variable actually defined in `defaults/main.yml` in the table; do not invent
  variables that are not implemented. If none exist yet, write
  "No role variables are defined yet." and remove the table.
- Use indented code blocks for playbooks (4 spaces, not fenced blocks) so they render
  correctly in Ansible Galaxy.

## Validation Checklist

- [ ] All repo URLs, download/binary URLs, GPG keys, checksums, and package names came
      from the user, not invented
- [ ] `meta/main.yml` has the correct `role_name`, description, and tags
- [ ] README describes the target role, no base-role text remains
- [ ] No `my_role` or placeholder debug tasks remain in `tasks/`
- [ ] All variables use the `<role_name>_` prefix
- [ ] Binary installs: checksum verification in place, and a systemd unit is either
      confirmed to ship with the package or created and installed by the role
- [ ] Molecule verifies the service is enabled and active (when the role manages a service)
- [ ] `molecule/default/converge.yml` references `carlosroman.<role_name>` and verifies it
- [ ] `make lint` passes
- [ ] `make test` passes
