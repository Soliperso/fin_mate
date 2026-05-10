-- Change goal_contributions.transaction_id FK from SET NULL to CASCADE DELETE
-- so that deleting a transaction automatically removes its linked contribution.
ALTER TABLE public.goal_contributions
  DROP CONSTRAINT IF EXISTS goal_contributions_transaction_id_fkey;

ALTER TABLE public.goal_contributions
  ADD CONSTRAINT goal_contributions_transaction_id_fkey
  FOREIGN KEY (transaction_id)
  REFERENCES public.transactions(id)
  ON DELETE CASCADE;
