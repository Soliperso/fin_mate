-- Create notification_types ENUM
CREATE TYPE notification_type AS ENUM (
    'budget_alert',
    'bill_reminder',
    'transaction_alert',
    'money_health_update',
    'goal_progress',
    'system_message'
);

-- Create notification_priority ENUM
CREATE TYPE notification_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    priority notification_priority DEFAULT 'medium',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    action_label VARCHAR(100),
    is_read BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    archived_at TIMESTAMP WITH TIME ZONE
);

-- Add indexes for performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_user_type ON notifications(user_id, type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_priority ON notifications(priority) WHERE is_read = FALSE;

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own notifications"
    ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
    ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- System can insert notifications for users
CREATE POLICY "System can insert notifications"
    ON notifications
    FOR INSERT
    WITH CHECK (true);

-- Function to create a notification
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type notification_type,
    p_title VARCHAR(255),
    p_message TEXT,
    p_priority notification_priority DEFAULT 'medium',
    p_action_url VARCHAR(500) DEFAULT NULL,
    p_action_label VARCHAR(100) DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        type,
        priority,
        title,
        message,
        action_url,
        action_label,
        metadata
    ) VALUES (
        p_user_id,
        p_type,
        p_priority,
        p_title,
        p_message,
        p_action_url,
        p_action_label,
        p_metadata
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_user_id UUID, p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = CURRENT_TIMESTAMP
    WHERE id = p_notification_id
        AND user_id = p_user_id;

    RETURN FOUND;
END;
$$;

-- Function to mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id
        AND is_read = FALSE;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- Function to archive notification
CREATE OR REPLACE FUNCTION archive_notification(p_user_id UUID, p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_archived = TRUE,
        archived_at = CURRENT_TIMESTAMP
    WHERE id = p_notification_id
        AND user_id = p_user_id;

    RETURN FOUND;
END;
$$;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM notifications
    WHERE user_id = p_user_id
        AND is_read = FALSE
        AND is_archived = FALSE;

    RETURN v_count;
END;
$$;

-- Function to check budget and create alert
CREATE OR REPLACE FUNCTION check_budget_alerts()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_budget RECORD;
    v_count INTEGER := 0;
BEGIN
    -- Check each active budget
    FOR v_budget IN
        SELECT
            b.id,
            b.user_id,
            b.category_id,
            b.amount AS budget_amount,
            b.period,
            c.name AS category_name,
            (
                SELECT COALESCE(SUM(t.amount), 0)
                FROM transactions t
                WHERE t.user_id = b.user_id
                    AND t.category_id = b.category_id
                    AND t.type = 'expense'
                    AND t.date >= CURRENT_DATE - INTERVAL '1 month'
            ) AS spent_amount
        FROM budgets b
        LEFT JOIN categories c ON c.id = b.category_id
        WHERE b.is_active = TRUE
    LOOP
        -- Check if budget exceeded 80%
        IF v_budget.spent_amount >= (v_budget.budget_amount * 0.8) THEN
            -- Check if notification doesn't already exist for this budget this month
            IF NOT EXISTS (
                SELECT 1
                FROM notifications
                WHERE user_id = v_budget.user_id
                    AND type = 'budget_alert'
                    AND metadata->>'budget_id' = v_budget.id::TEXT
                    AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
            ) THEN
                PERFORM create_notification(
                    v_budget.user_id,
                    'budget_alert',
                    'Budget Alert: ' || COALESCE(v_budget.category_name, 'General'),
                    format('You''ve spent $%s of your $%s budget (%s%%)',
                        ROUND(v_budget.spent_amount, 2),
                        ROUND(v_budget.budget_amount, 2),
                        ROUND((v_budget.spent_amount / v_budget.budget_amount) * 100, 0)
                    ),
                    CASE
                        WHEN v_budget.spent_amount >= v_budget.budget_amount THEN 'urgent'::notification_priority
                        WHEN v_budget.spent_amount >= (v_budget.budget_amount * 0.9) THEN 'high'::notification_priority
                        ELSE 'medium'::notification_priority
                    END,
                    '/budgets',
                    'View Budget',
                    jsonb_build_object('budget_id', v_budget.id)
                );
                v_count := v_count + 1;
            END IF;
        END IF;
    END LOOP;

    RETURN v_count;
END;
$$;

-- Function to create bill reminder notifications
CREATE OR REPLACE FUNCTION create_bill_reminders()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_bill RECORD;
    v_count INTEGER := 0;
BEGIN
    -- Check upcoming bills in next 3 days
    FOR v_bill IN
        SELECT
            rt.id,
            rt.user_id,
            rt.description,
            rt.amount,
            rt.next_occurrence,
            c.name AS category_name
        FROM recurring_transactions rt
        LEFT JOIN categories c ON c.id = rt.category_id
        WHERE rt.is_active = TRUE
            AND rt.next_occurrence >= CURRENT_DATE
            AND rt.next_occurrence <= CURRENT_DATE + INTERVAL '3 days'
    LOOP
        -- Check if notification doesn't already exist for this bill
        IF NOT EXISTS (
            SELECT 1
            FROM notifications
            WHERE user_id = v_bill.user_id
                AND type = 'bill_reminder'
                AND metadata->>'recurring_transaction_id' = v_bill.id::TEXT
                AND created_at >= CURRENT_DATE
        ) THEN
            PERFORM create_notification(
                v_bill.user_id,
                'bill_reminder',
                'Upcoming Bill: ' || v_bill.description,
                format('$%s due on %s',
                    ROUND(v_bill.amount, 2),
                    TO_CHAR(v_bill.next_occurrence, 'Mon DD')
                ),
                CASE
                    WHEN v_bill.next_occurrence = CURRENT_DATE THEN 'urgent'::notification_priority
                    WHEN v_bill.next_occurrence = CURRENT_DATE + INTERVAL '1 day' THEN 'high'::notification_priority
                    ELSE 'medium'::notification_priority
                END,
                '/bills',
                'View Bills',
                jsonb_build_object('recurring_transaction_id', v_bill.id)
            );
            v_count := v_count + 1;
        END IF;
    END LOOP;

    RETURN v_count;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_notification(UUID, notification_type, VARCHAR, TEXT, notification_priority, VARCHAR, VARCHAR, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read() TO authenticated;
GRANT EXECUTE ON FUNCTION archive_notification(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count() TO authenticated;
GRANT EXECUTE ON FUNCTION check_budget_alerts() TO authenticated;
GRANT EXECUTE ON FUNCTION create_bill_reminders() TO authenticated;

-- Comment the table
COMMENT ON TABLE notifications IS 'User notifications for budget alerts, bill reminders, and other system messages';
COMMENT ON COLUMN notifications.metadata IS 'Additional data related to the notification (budget_id, transaction_id, etc.)';
COMMENT ON COLUMN notifications.action_url IS 'Deep link to the relevant screen in the app';
