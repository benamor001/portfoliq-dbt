-- =============================================================================
-- portfoliq pack: sat_asset_metadata_public
-- Source : star_public.sat_asset_metadata_public
-- Grain  : asset_hk — one row per asset (current record, R1 multi-source)
-- Toggle : portfoliq_enable_star
-- Exposure: public_recomputed (Sprint 16A T-219)
--
-- Pass-through view of the public metadata satellite.
-- Use dim_asset for SCD2 history. Use this satellite for direct metadata joins.
--
-- Legal  : coingecko_id excluded (CoinGecko ToS §6.2).
--          Not financial advice. Methodology disclosed.
-- Licence: ELv2 — see NOTICE.md
-- =============================================================================

{{ assert_star_enabled() }}

select *
from {{ source('portfoliq', 'sat_asset_metadata_public') }}

{% if not var('portfoliq_enable_star', true) %}
where false
{% endif %}
