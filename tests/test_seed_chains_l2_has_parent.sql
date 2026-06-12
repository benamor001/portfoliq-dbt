-- =============================================================================
-- Singular test: test_seed_chains_l2_has_parent
-- Asserts: every L2 chain MUST have a non-null parent_chain_id.
--
-- Business rule: if is_l2 = true, the chain was built on top of a parent L1.
-- A missing parent_chain_id on an L2 is a data entry error.
--
-- Returns non-empty set (= FAIL) if any L2 has NULL parent_chain_id.
-- =============================================================================

select
    chain_id,
    chain_name,
    is_l2,
    parent_chain_id
from {{ ref('dim_chain') }}
where is_l2 = true
  and parent_chain_id is null
