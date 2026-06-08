# portfoliq-dbt — convenience targets
#
# The integration_tests/ directory is a BLANK consumer project that installs
# this package via a local path and proves it resolves (dbt deps + dbt parse).
# That is the operational test that proves the package is distributable.

.PHONY: help deps parse list ci clean pre-publish-check

help:
	@echo "portfoliq-dbt — Makefile targets"
	@echo ""
	@echo "  make deps               dbt deps in integration_tests/ (installs the pack locally)"
	@echo "  make parse              dbt parse the pack from the blank consumer project"
	@echo "  make list               list the models the pack exposes"
	@echo "  make ci                 deps + parse (the distributability gate)"
	@echo "  make pre-publish-check  verify no artifacts/credentials would be pushed"
	@echo "  make clean              remove target/ and dbt_packages/"

deps:
	cd integration_tests && DBT_PROFILES_DIR=. dbt deps

parse: deps
	cd integration_tests && DBT_PROFILES_DIR=. dbt parse

list: deps
	cd integration_tests && DBT_PROFILES_DIR=. dbt list --resource-type model

ci: parse
	@echo "[ci] portfoliq-dbt — package installs from a blank project and parses. GREEN."

# Anti-leak guard — run before any public push. All conditions must hold.
pre-publish-check:
	@set -e; \
	fail=0; \
	for d in target dbt_packages logs .dbt; do \
	  if [ -e "$$d" ]; then echo "LEAK: $$d present at package root"; fail=1; fi; \
	done; \
	if [ -e profiles.yml ]; then echo "LEAK: profiles.yml (credentials) present — only profiles.yml.example allowed"; fail=1; fi; \
	if [ -e .user.yml ]; then echo "LEAK: .user.yml present"; fail=1; fi; \
	if [ -d portfoliq ]; then echo "LEAK: nested portfoliq/ dbt project present (must be a single root project)"; fail=1; fi; \
	n=$$(find . -name dbt_project.yml -not -path './dbt_packages/*' -not -path './integration_tests/*' | wc -l); \
	if [ "$$n" -ne 1 ]; then echo "STRUCTURE: expected exactly 1 root dbt_project.yml, found $$n"; fail=1; fi; \
	if grep -rqi "License: MIT\|MIT-licensed\|LICENSE present (MIT)" --include=*.md --include=LICENSE . ; then echo "LICENCE: package-licence MIT mention found (must be ELv2)"; fail=1; fi; \
	if [ "$$fail" -ne 0 ]; then echo "pre-publish-check FAILED"; exit 1; fi; \
	echo "[pre-publish-check] clean — safe to push"

clean:
	rm -rf target dbt_packages logs
	rm -rf integration_tests/target integration_tests/dbt_packages integration_tests/logs
	@echo "[clean] done"
