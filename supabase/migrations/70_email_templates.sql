-- Email templates for admin management.
-- Admins can edit subject, body, and enabled status.
-- Templates are seeded at migration time; the UI does not support create/delete.

CREATE TABLE IF NOT EXISTS email_templates (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT        UNIQUE NOT NULL,
  name        TEXT        NOT NULL,
  description TEXT        NOT NULL DEFAULT '',
  subject     TEXT        NOT NULL DEFAULT '',
  body        TEXT        NOT NULL DEFAULT '',
  is_enabled  BOOLEAN     NOT NULL DEFAULT TRUE,
  variables   JSONB       NOT NULL DEFAULT '[]',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default templates (idempotent)
INSERT INTO email_templates (key, name, description, subject, body, variables) VALUES
(
  'welcome',
  'Welcome Email',
  'Sent to new users after account creation',
  'Welcome to Finmate, {{user_name}}!',
  E'Hi {{user_name}},\n\nWelcome to Finmate! We''re excited to have you on board.\n\nStart tracking your finances today and take control of your financial future.\n\nBest,\nThe Finmate Team',
  '[{"key":"user_name","description":"User''s display name"}]'
),
(
  'password_reset',
  'Password Reset',
  'Sent when a user requests a password reset',
  'Reset your Finmate password',
  E'Hi {{user_name}},\n\nYou requested a password reset. Click the link below:\n\n{{reset_link}}\n\nThis link expires in 24 hours. If you didn''t request this, please ignore this email.\n\nBest,\nThe Finmate Team',
  '[{"key":"user_name","description":"User''s display name"},{"key":"reset_link","description":"Password reset URL"}]'
),
(
  'budget_alert',
  'Budget Alert',
  'Sent when a user reaches 80% of a budget category',
  'Budget Alert: {{category}} is at {{percentage}}%',
  E'Hi {{user_name}},\n\nYour {{category}} budget is at {{percentage}}% for this month.\n\nRemaining: {{remaining}} of {{budget_amount}}.\n\nLog in to review your spending.\n\nBest,\nThe Finmate Team',
  '[{"key":"user_name","description":"User''s display name"},{"key":"category","description":"Budget category name"},{"key":"percentage","description":"Percentage used"},{"key":"remaining","description":"Amount remaining"},{"key":"budget_amount","description":"Total budget amount"}]'
),
(
  'goal_achieved',
  'Goal Achieved',
  'Sent when a user reaches a savings goal',
  'You reached your {{goal_name}} goal!',
  E'Hi {{user_name}},\n\nCongratulations! You''ve successfully reached your {{goal_name}} savings goal of {{goal_amount}}.\n\nKeep up the great work!\n\nBest,\nThe Finmate Team',
  '[{"key":"user_name","description":"User''s display name"},{"key":"goal_name","description":"Savings goal name"},{"key":"goal_amount","description":"Goal target amount"}]'
),
(
  'recurring_reminder',
  'Recurring Transaction Reminder',
  'Sent the day before a recurring transaction is due',
  'Reminder: {{transaction_name}} is due tomorrow',
  E'Hi {{user_name}},\n\nThis is a reminder that your recurring transaction "{{transaction_name}}" of {{amount}} is scheduled for tomorrow.\n\nOpen Finmate to mark it as paid or make adjustments.\n\nBest,\nThe Finmate Team',
  '[{"key":"user_name","description":"User''s display name"},{"key":"transaction_name","description":"Recurring transaction name"},{"key":"amount","description":"Transaction amount"}]'
)
ON CONFLICT (key) DO NOTHING;

-- RLS
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage email templates"
  ON email_templates
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- RPC: list all templates (admin only)
CREATE OR REPLACE FUNCTION admin_get_email_templates()
RETURNS TABLE (
  id          UUID,
  key         TEXT,
  name        TEXT,
  description TEXT,
  subject     TEXT,
  body        TEXT,
  is_enabled  BOOLEAN,
  variables   JSONB,
  updated_at  TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
    SELECT t.id, t.key, t.name, t.description, t.subject, t.body,
           t.is_enabled, t.variables, t.updated_at
    FROM email_templates t
    ORDER BY t.name;
END;
$$;

-- RPC: update subject, body, and enabled status (admin only)
CREATE OR REPLACE FUNCTION admin_update_email_template(
  p_id         UUID,
  p_subject    TEXT,
  p_body       TEXT,
  p_is_enabled BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE email_templates
  SET subject    = p_subject,
      body       = p_body,
      is_enabled = p_is_enabled,
      updated_at = NOW()
  WHERE id = p_id;
END;
$$;
