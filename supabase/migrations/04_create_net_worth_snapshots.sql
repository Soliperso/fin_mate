-- Create net_worth_snapshots table for historical tracking
CREATE TABLE IF NOT EXISTS net_worth_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    net_worth DECIMAL(15, 2) NOT NULL,
    snapshot_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, snapshot_date)
);

-- Add indexes for performance
CREATE INDEX idx_net_worth_snapshots_user_id ON net_worth_snapshots(user_id);
CREATE INDEX idx_net_worth_snapshots_date ON net_worth_snapshots(snapshot_date DESC);
CREATE INDEX idx_net_worth_snapshots_user_date ON net_worth_snapshots(user_id, snapshot_date DESC);

-- Enable RLS
ALTER TABLE net_worth_snapshots ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own net worth snapshots"
    ON net_worth_snapshots
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own net worth snapshots"
    ON net_worth_snapshots
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own net worth snapshots"
    ON net_worth_snapshots
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own net worth snapshots"
    ON net_worth_snapshots
    FOR DELETE
    USING (auth.uid() = user_id);

-- Function to calculate current net worth
CREATE OR REPLACE FUNCTION calculate_current_net_worth(p_user_id UUID)
RETURNS DECIMAL(15, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_net_worth DECIMAL(15, 2);
BEGIN
    SELECT COALESCE(SUM(balance), 0)
    INTO v_net_worth
    FROM accounts
    WHERE user_id = p_user_id AND is_active = true;

    RETURN v_net_worth;
END;
$$;

-- Function to create a net worth snapshot
CREATE OR REPLACE FUNCTION create_net_worth_snapshot(p_user_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_net_worth DECIMAL(15, 2);
    v_snapshot_id UUID;
BEGIN
    -- Calculate current net worth
    v_net_worth := calculate_current_net_worth(p_user_id);

    -- Insert or update snapshot
    INSERT INTO net_worth_snapshots (user_id, net_worth, snapshot_date)
    VALUES (p_user_id, v_net_worth, p_date)
    ON CONFLICT (user_id, snapshot_date)
    DO UPDATE SET net_worth = EXCLUDED.net_worth
    RETURNING id INTO v_snapshot_id;

    RETURN v_snapshot_id;
END;
$$;

-- Function to get net worth snapshots for a date range
CREATE OR REPLACE FUNCTION get_net_worth_snapshots(
    p_user_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    snapshot_date DATE,
    net_worth DECIMAL(15, 2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        nws.snapshot_date,
        nws.net_worth
    FROM net_worth_snapshots nws
    WHERE nws.user_id = p_user_id
        AND nws.snapshot_date >= p_start_date
        AND nws.snapshot_date <= p_end_date
    ORDER BY nws.snapshot_date ASC;
END;
$$;

-- Function to automatically create daily snapshots (can be called by a cron job)
CREATE OR REPLACE FUNCTION create_daily_snapshots()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user RECORD;
    v_count INTEGER := 0;
BEGIN
    -- Create snapshot for each user with active accounts
    FOR v_user IN
        SELECT DISTINCT user_id
        FROM accounts
        WHERE is_active = true
    LOOP
        PERFORM create_net_worth_snapshot(v_user.user_id, CURRENT_DATE);
        v_count := v_count + 1;
    END LOOP;

    RETURN v_count;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_current_net_worth(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_net_worth_snapshot(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_net_worth_snapshots(UUID, DATE, DATE) TO authenticated;

-- Comment the table
COMMENT ON TABLE net_worth_snapshots IS 'Historical snapshots of user net worth for trend analysis';
COMMENT ON COLUMN net_worth_snapshots.snapshot_date IS 'Date of the snapshot (one per day per user)';
COMMENT ON COLUMN net_worth_snapshots.net_worth IS 'Total net worth across all active accounts at snapshot time';
