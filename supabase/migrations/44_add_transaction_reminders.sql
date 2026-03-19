-- Migration 44: Transaction Reminders
-- Allows users to attach reminders to transactions, fired as in-app notifications

CREATE TABLE IF NOT EXISTS transaction_reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    remind_at DATE NOT NULL,
    days_before INT NOT NULL DEFAULT 1,
    message TEXT,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transaction_reminders_user ON transaction_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_reminders_due ON transaction_reminders(remind_at) WHERE is_sent = FALSE;

ALTER TABLE transaction_reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own reminders" ON transaction_reminders
    FOR ALL USING (auth.uid() = user_id);

-- Process due reminders: creates in-app notifications for reminders whose remind_at <= today
CREATE OR REPLACE FUNCTION process_transaction_reminders()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_reminder RECORD;
    v_count INT := 0;
BEGIN
    FOR v_reminder IN
        SELECT tr.*, t.description, t.amount, t.date AS tx_date
        FROM transaction_reminders tr
        JOIN transactions t ON t.id = tr.transaction_id
        WHERE tr.remind_at <= CURRENT_DATE AND tr.is_sent = FALSE
    LOOP
        PERFORM create_notification(
            v_reminder.user_id,
            'bill_reminder',
            'Reminder: ' || COALESCE(v_reminder.description, 'Transaction'),
            COALESCE(
                v_reminder.message,
                format('$%s due on %s',
                    ROUND(v_reminder.amount, 2),
                    TO_CHAR(v_reminder.tx_date, 'Mon DD'))
            ),
            'high',
            '/transactions/' || v_reminder.transaction_id,
            'View Transaction',
            jsonb_build_object('transaction_id', v_reminder.transaction_id)
        );
        UPDATE transaction_reminders
            SET is_sent = TRUE, sent_at = NOW()
            WHERE id = v_reminder.id;
        v_count := v_count + 1;
    END LOOP;
    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION process_transaction_reminders() TO authenticated;
