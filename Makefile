-include .env

MOLECULE_TEST ?= uv run molecule test

.PHONY : setup
setup :
	@(uv sync)

.PHONY : test
test :
	@(${MOLECULE_TEST})

.PHONY : test/latest
test/latest :
	@(MOLECULE_PLAYBOOK=converge-latest.yml ${MOLECULE_TEST})

# ACME resolver opt-in variant (molecule/default/converge-acme.yml).
.PHONY : test/acme
test/acme :
	@(MOLECULE_PLAYBOOK=converge-acme.yml ${MOLECULE_TEST})

# apt-like version management semantics (molecule/default/converge-state.yml):
# the traefik_state reject cases, then state=latest through to idempotence.
.PHONY : test/state
test/state :
	@(MOLECULE_PLAYBOOK=converge-state.yml ${MOLECULE_TEST})

# Pin-flip path on one instance: converge the v3.7.17 pin, then re-converge
# with the v3.7.19 pin and prove the in-place upgrade restarts the service
# exactly once, then flip back to v3.7.17 to prove the downgrade path too
# (molecule/default/converge-upgrade-*.yml).
.PHONY : test/upgrade
test/upgrade :
	@(uv run molecule destroy || true ; \
	  MOLECULE_PLAYBOOK=converge-upgrade-old.yml uv run molecule converge && \
	  MOLECULE_PLAYBOOK=converge-upgrade-new.yml uv run molecule converge && \
	  MOLECULE_PLAYBOOK=converge-upgrade-old.yml uv run molecule converge)

# apt remove semantics on one instance: install, absent, absent again (the
# repeat must report changed=0), then install again
# (molecule/default/converge-absent.yml).
.PHONY : test/absent
test/absent :
	@(uv run molecule destroy || true ; \
	  uv run molecule converge && \
	  MOLECULE_PLAYBOOK=converge-absent.yml uv run molecule converge && \
	  MOLECULE_PLAYBOOK=converge-absent.yml uv run molecule converge && \
	  uv run molecule converge)

.PHONY : test/acme/ubuntu-2604
test/acme/ubuntu-2604 :
	@(MOLECULE_DISTRO=ubuntu2604 MOLECULE_PLAYBOOK=converge-acme.yml ${MOLECULE_TEST})

.PHONY : test/ubuntu-2604
test/ubuntu-2604 :
	@(MOLECULE_DISTRO=ubuntu2604 ${MOLECULE_TEST})

.PHONY : test/ubuntu-2404
test/ubuntu-2404 :
	@(MOLECULE_DISTRO=ubuntu2404 ${MOLECULE_TEST})

.PHONY : test/ubuntu-2204
test/ubuntu-2204 :
	@(MOLECULE_DISTRO=ubuntu2204 ${MOLECULE_TEST})

.PHONY : test/debian-13
test/debian-13 :
	@(MOLECULE_DISTRO=debian13 ${MOLECULE_TEST})

.PHONY : test/debian-12
test/debian-12 :
	@(MOLECULE_DISTRO=debian12 ${MOLECULE_TEST})

.PHONY : test/rocky-9
test/rocky-9 :
	@(MOLECULE_DISTRO=rockylinux9 ${MOLECULE_TEST})

.PHONY : test/rocky-10
test/rocky-10 :
	@(MOLECULE_DISTRO=rockylinux10 ${MOLECULE_TEST})

.PHONY : test/amazonlinux-2023
test/amazonlinux-2023 :
	@(MOLECULE_DISTRO=amazonlinux2023 ${MOLECULE_TEST})

.PHONY : test/fedora-44
test/fedora-44 :
	@(MOLECULE_DISTRO=fedora44 ${MOLECULE_TEST})

.PHONY : test/all
test/all : test/ubuntu-2604
test/all : test/ubuntu-2404
test/all : test/ubuntu-2204
test/all : test/debian-13
test/all : test/debian-12
test/all : test/fedora-44
test/all : test/rocky-10
test/all : test/rocky-9
test/all : test/amazonlinux-2023

.PHONY : lint
lint :
	@(uv run yamllint .)
