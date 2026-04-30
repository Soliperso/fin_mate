-- Extend recurring_interval CHECK constraint to include 'biweekly'.
-- PostgreSQL inline CHECK constraints are auto-named; drop by the generated
-- name and re-add with the expanded value list.

ALTER TABLE public.transactions
  DROP CONSTRAINT IF EXISTS transactions_recurring_interval_check;

ALTER TABLE public.transactions
  ADD CONSTRAINT transactions_recurring_interval_check
    CHECK (recurring_interval IN ('daily', 'weekly', 'biweekly', 'monthly', 'yearly'));
