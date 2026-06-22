-- Add recurring_interval column to transactions table.
-- The recurring_interval field existed in the Dart model/entity but had no
-- corresponding DB column. This migration adds it with a CHECK constraint
-- matching the values used in the app.

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS recurring_interval TEXT
    CHECK (recurring_interval IN ('daily', 'weekly', 'monthly', 'yearly'));
