-- ============================================================================
-- DELETE ALL TEST DATA
-- ============================================================================

DELETE FROM public.goal_contributions;
DELETE FROM public.savings_goals;
DELETE FROM public.transactions;
DELETE FROM public.recurring_transactions;
DELETE FROM public.budgets;
DELETE FROM public.accounts;

-- Re-create default cash account for each user
INSERT INTO public.accounts (user_id, name, type, balance, currency)
SELECT DISTINCT id, 'Cash', 'cash', 0, 'USD'
FROM public.user_profiles;
