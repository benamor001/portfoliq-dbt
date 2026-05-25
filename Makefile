# portfoliq-dbt-pack — convenience targets

.PHONY: help install bootstrap parse build test ci clean

help:
	@echo "portfoliq-dbt-pack — Makefile targets"
	@echo ""
	@echo "  make install      Install Python deps for the bootstrap script"
	@echo "  make bootstrap    Fetch data from portfolIQ API → seeds/generated/"
	@echo "                    Requires PORTFOLIQ_API_KEY env."
	@echo "  make parse        dbt parse (integration_tests/)"
	@echo "  make build        dbt build (integration_tests/, DuckDB)"
	@echo "  make test         dbt test (integration_tests/, DuckDB)"
	@echo "  make ci           parse + build + test (used by GitHub Actions)"
	@echo "  make clean        Remove target/ and dbt_packages/"

install:
	pip install requests dbt-duckdb dbt-postgres

bootstrap:
	python scripts/piq_bootstrap.py

parse:
	cd integration_tests && DBT_PROFILES_DIR=. dbt deps && DBT_PROFILES_DIR=. dbt parse

build:
	cd integration_tests && DBT_PROFILES_DIR=. dbt deps && \
	    DBT_PROFILES_DIR=. dbt build --select portfoliq --target duckdb

test:
	cd integration_tests && DBT_PROFILES_DIR=. dbt test --select portfoliq --target duckdb

ci: parse build
	@echo "[ci] portfoliq-dbt-pack — green"

clean:
	rm -rf integration_tests/target integration_tests/dbt_packages
	rm -rf seeds/generated/*.csv
	@echo "[clean] done"
