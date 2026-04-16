-- Migration 54: Make notification functions respect user preferences
-- Updates create_bill_reminders(), check_budget_alerts(), and adds check_transaction_alert()

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. create_bill_reminders()
--    Now reads each user's notification_preferences to honour:
--      • push_enabled      — master switch; skip user if false
--      • bill_reminders    — toggle; skip user if false
--      • bill_reminder_days — lookahead window (1-7, default 3)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_bill_reminders()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_bill        RECORD;
    v_prefs       JSONB;
    v_push        BOOLEAN;
    v_enabled     BOOLEAN;
    v_days        INTEGER;
    v_count       INTEGER := 0;
BEGIN
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
    LOOP
        -- Read this user's preferences
        SELECT COALESCE(notification_preferences, '{}'::jsonb)
          INTO v_prefs
          FROM user_profiles
         WHERE id = v_bill.user_id;

        v_push    := COALESCE((v_prefs->>'push_enabled')::BOOLEAN,    TRUE);
        v_enabled := COALESCE((v_prefs->>'bill_reminders')::BOOLEAN,  TRUE);
        v_days    := COALESCE((v_prefs->>'bill_reminder_days')::INTEGER, 3);

        -- Skip if notifications are off for this user
        CONTINUE WHEN NOT v_push OR NOT v_enabled;

        -- Skip if outside the lookahead window
        CONTINUE WHEN v_bill.next_occurrence > CURRENT_DATE + (v_days || ' days')::INTERVAL;

        -- Only create if no reminder was already sent today for this bill
        IF NOT EXISTS (
            SELECT 1
            FROM notifications
            WHERE user_id  = v_bill.user_id
              AND type      = 'bill_reminder'
              AND metadata->>'recurring_transaction_id' = v_bill.id::TEXT
              AND created_at >= CURRENT_DATE
        ) THEN
            PERFORM create_notification(
                v_bill.user_id,
                'bill_reminder',
                'Upcoming Bill: ' || COALESCE(v_bill.description, v_bill.category_name, 'Bill'),
                format('$%s due on %s',
                    ROUND(v_bill.amount, 2),
                    TO_CHAR(v_bill.next_occurrence, 'Mon DD')),
                CASE
                    WHEN v_bill.next_occurrence = CURRENT_DATE              THEN 'urgent'::notification_priority
                    WHEN v_bill.next_occurrence = CURRENT_DATE + INTERVAL '1 day' THEN 'high'::notification_priority
                    ELSE 'medium'::notification_priority
                END,
                '/recurring-transactions',
                'View Bills',
                jsonb_build_object('recurring_transaction_id', v_bill.id)
            );
            v_count := v_count + 1;
        END IF;
    END LOOP;

    RETURN v_count;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. check_budget_alerts()
--    Now reads each user's notification_preferences to honour:
--      • push_enabled      — master switch
--      • budget_alerts     — toggle
--      • budget_threshold  — alert percentage (10-100, default 80)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_budget_alerts()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_budget    RECORD;
    v_prefs     JSONB;
    v_push      BOOLEAN;
    v_enabled   BOOLEAN;
    v_threshold NUMERIC;
    v_count     INTEGER := 0;
BEGIN
    FOR v_budget IN
        SELECT
            b.id,
            b.user_id,
            b.category_id,
            b.amount AS budget_amount,
            b.period,
            c.name   AS category_name,
            (
                SELECT COALESCE(SUM(t.amount), 0)
                FROM transactions t
                WHERE t.user_id     = b.user_id
                  AND t.category_id = b.category_id
                  AND t.type        = 'expense'
                  AND t.date        >= CURRENT_DATE - INTERVAL '1 month'
            ) AS spent_amount
        FROM budgets b
        LEFT JOIN categories c ON c.id = b.category_id
        WHERE b.is_active = TRUE
    LOOP
        -- Read this user's preferences
        SELECT COALESCE(notification_preferences, '{}'::jsonb)
          INTO v_prefs
          FROM user_profiles
         WHERE id = v_budget.user_id;

        v_push      := COALESCE((v_prefs->>'push_enabled')::BOOLEAN,    TRUE);
        v_enabled   := COALESCE((v_prefs->>'budget_alerts')::BOOLEAN,   TRUE);
        v_threshold := COALESCE((v_prefs->>'budget_threshold')::NUMERIC, 80);

        CONTINUE WHEN NOT v_push OR NOT v_enabled;

        -- Alert when spend reaches the user's chosen threshold
        IF v_budget.spent_amount >= (v_budget.budget_amount * v_threshold / 100.0) THEN
            IF NOT EXISTS (
                SELECT 1
                FROM notifications
                WHERE user_id = v_budget.user_id
                  AND type    = 'budget_alert'
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
                        ROUND((v_budget.spent_amount / v_budget.budget_amount) * 100, 0)),
                    CASE
                        WHEN v_budget.spent_amount >= v_budget.budget_amount                      THEN 'urgent'::notification_priority
                        WHEN v_budget.spent_amount >= (v_budget.budget_amount * 0.9)              THEN 'high'::notification_priority
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. check_transaction_alert()  (new)
--    Called from the client after a transaction is saved. Creates a
--    transaction_alert notification if:
--      • push_enabled       is true
--      • transaction_alerts is true
--      • amount             >= transaction_threshold
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_transaction_alert(
    p_user_id        UUID,
    p_amount         NUMERIC,
    p_description    TEXT,
    p_transaction_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_prefs     JSONB;
    v_push      BOOLEAN;
    v_enabled   BOOLEAN;
    v_threshold NUMERIC;
BEGIN
    SELECT COALESCE(notification_preferences, '{}'::jsonb)
      INTO v_prefs
      FROM user_profiles
     WHERE id = p_user_id;

    v_push      := COALESCE((v_prefs->>'push_enabled')::BOOLEAN,         TRUE);
    v_enabled   := COALESCE((v_prefs->>'transaction_alerts')::BOOLEAN,   FALSE);
    v_threshold := COALESCE((v_prefs->>'transaction_threshold')::NUMERIC, 1000);

    IF NOT v_push OR NOT v_enabled THEN
        RETURN FALSE;
    END IF;

    IF p_amount < v_threshold THEN
        RETURN FALSE;
    END IF;

    PERFORM create_notification(
        p_user_id,
        'transaction_alert',
        'Large Transaction Recorded',
        format('A transaction of $%s was recorded: %s',
            ROUND(p_amount, 2),
            COALESCE(p_description, 'No description')),
        CASE
            WHEN p_amount >= v_threshold * 5 THEN 'high'::notification_priority
            ELSE 'medium'::notification_priority
        END,
        '/transactions/' || p_transaction_id,
        'View Transaction',
        jsonb_build_object('transaction_id', p_transaction_id, 'amount', p_amount)
    );

    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION check_transaction_alert(UUID, NUMERIC, TEXT, UUID) TO authenticated;
