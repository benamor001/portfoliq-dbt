-- =============================================================================
-- Singular test: test_seed_analysis_type_enabled_has_model
-- Asserts: every enabled analysis type MUST have a non-null model_default.
--
-- Business rule: is_enabled=true means the AI pipeline will use this type.
-- A NULL model_default on an enabled type would break the prompt router.
--
-- Returns non-empty set (= FAIL) if any enabled type has no model_default.
-- =============================================================================

select
    analysis_type_id,
    analysis_type_label,
    model_default,
    is_enabled
from {{ ref('dim_analysis_type') }}
where is_enabled = true
  and model_default is null
