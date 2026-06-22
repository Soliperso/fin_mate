-- Migration 90: Fix notifications INSERT policy.
-- The previous policy used WITH CHECK (true), allowing any authenticated
-- user to insert notifications for any user_id. This replaces it with a
-- strict owner-only policy. All system/admin notification inserts already
-- go through SECURITY DEFINER RPCs (create_notification, check_budget_alerts,
-- create_bill_reminders, check_transaction_alert, admin_broadcast_notification)
-- which bypass RLS, so this change does not break any existing functionality.

DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;

CREATE POLICY "Users can insert own notifications" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);
