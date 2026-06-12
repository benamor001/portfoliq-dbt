# dbt Hub submission — `benamor001/portfoliq-dbt`

> Status: **not submitted.** Primary distribution is **git-install** (see README).
> A dbt Hub listing is **optional and not guaranteed**: the package is licensed under
> the **Elastic License v2 (ELv2)**, which is **not an OSI-approved open-source licence**.
> dbt Hub / hubcap historically favours OSI licences, so a submission may be declined.
> Do not block distribution on Hub approval — git-install works identically.

## Canonical facts (single source of truth)

| Field | Value |
|---|---|
| Package name (`dbt_project.yml`) | `portfoliq` |
| Version | `0.2.0` |
| Licence | Elastic License v2 (ELv2) — non-OSI |
| `require-dbt-version` | `[">=1.7.0", "<2.0.0"]` |
| Adapters | postgres (primary), duckdb (local dev) |
| Public repo | `https://github.com/benamor001/portfoliq-dbt` |
| Release tag | `v0.2.0` (to be created on the public repo) |

## Pre-flight checklist (state today)

- [x] `dbt_project.yml` has `name: 'portfoliq'`, `version: '0.2.0'`
- [x] `require-dbt-version: [">=1.7.0", "<2.0.0"]` set
- [x] `LICENSE` present at package root — **ELv2** (single licence, no MIT)
- [x] `README.md` with git-install instructions + honest scope (crypto-only v0.2.0)
- [x] `dbt parse` passes locally (postgres adapter)
- [ ] Public repo created on GitHub — **Wael action** (account/org required)
- [ ] `v0.2.0` tag pushed to the public repo — **Wael action**

## If a Hub listing is still wanted (optional, after public push)

hubcap requires a public repo + a semver tag. Steps (only if pursuing Hub despite ELv2):

1. Open a PR on [`dbt-labs/hubcap`](https://github.com/dbt-labs/hubcap) adding
   `"benamor001": ["portfoliq-dbt"]` to `hub.json`.
2. A dbt Labs maintainer reviews. **Expect questions on the non-OSI ELv2 licence** —
   be ready to either accept rejection or relicense (we will NOT relicense to MIT/Apache:
   ELv2 is the moat per COMITE-010 cond. 8).
3. If merged, `hubcap.py` indexes the `v0.2.0` tag within ~1h.

## Primary channel (always works, no Hub needed)

```yaml
packages:
  - git: "https://github.com/benamor001/portfoliq-dbt.git"
    revision: v0.2.0
```

This is functionally identical to a Hub install. The Hub listing is purely a
discoverability benefit — the package is fully shippable via git today.
