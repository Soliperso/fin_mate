-- ============================================================================
-- FIX: Net worth snapshots now use calculate_true_net_worth (includes debts)
-- ============================================================================
-- The original create_net_worth_snapshot() called calculate_current_net_worth(),
-- which only summed account balances and ignored the debts table.
-- This migration updates it to call calculate_true_net_worth() so that
-- historical snapshots (and the trend chart) correctly reflect liabilities.
-- ============================================================================

CREATE OR REPLACE FUNCTION create_net_worth_snapshot(p_user_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_net_worth   DECIMAL(15, 2);
    v_snapshot_id UUID;
BEGIN
    v_net_worth := calculate_true_net_worth(p_user_id);

    INSERT INTO net_worth_snapshots (user_id, net_worth, snapshot_date)
    VALUES (p_user_id, v_net_worth, p_date)
    ON CONFLICT (user_id, snapshot_date)
    DO UPDATE SET net_worth = EXCLUDED.net_worth
    RETURNING id INTO v_snapshot_id;

    RETURN v_snapshot_id;
END;
$$;
