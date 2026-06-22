-- Drop bill splitting related tables
-- This migration removes all tables related to the bill splitting feature which has been deprecated

-- Drop tables in reverse order of dependencies
DROP TABLE IF EXISTS settlements CASCADE;
DROP TABLE IF EXISTS expense_splits CASCADE;
DROP TABLE IF EXISTS group_expenses CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS bill_groups CASCADE;

-- Drop related functions
DROP FUNCTION IF EXISTS get_group_balances(uuid);
