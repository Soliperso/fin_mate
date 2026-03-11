-- Add original_balance to debts table for progress tracking
-- original_balance stores the initial debt amount and never changes after creation

ALTER TABLE debts ADD COLUMN IF NOT EXISTS original_balance DECIMAL(15,2);

-- Backfill existing rows — use current balance as best approximation
UPDATE debts SET original_balance = balance WHERE original_balance IS NULL;
