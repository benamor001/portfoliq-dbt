-- =============================================================================
-- Singular test: test_seed_chains_evm_l2_flags_coherent
-- Asserts: no row where is_l2 = true AND is_evm = false
--
-- Starknet exception: Starknet is L2 but NOT EVM (Cairo VM).
-- This test documents that Starknet is the only known EVM=false L2.
-- The test enforces business logic: all NEW L2s added must be EVM
-- (our current coverage scope). Starknet is pre-approved as an exception.
--
-- If a new non-EVM L2 is added, update this test with an explicit exception.
--
-- Returns non-empty set (= FAIL) if any non-approved non-EVM L2 is found.
-- =============================================================================

select
    chain_id,
    chain_name,
    is_evm,
    is_l2
from {{ ref('dim_chain') }}
where is_l2 = true
  and is_evm = false
  -- Approved exception: Starknet uses Cairo VM (not EVM), but is a valid L2.
  and chain_id != 'starknet'
