-- Migration 62: Normalize full_name to title case (initcap)
-- Backfills existing rows and adds a trigger to apply initcap on future writes.

-- Backfill existing names
UPDATE public.user_profiles
SET full_name = initcap(full_name)
WHERE full_name IS NOT NULL
  AND full_name <> initcap(full_name);

-- Trigger function: normalize full_name on every insert/update
CREATE OR REPLACE FUNCTION normalize_full_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.full_name IS NOT NULL THEN
    NEW.full_name := initcap(NEW.full_name);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_normalize_full_name ON public.user_profiles;
CREATE TRIGGER trg_normalize_full_name
  BEFORE INSERT OR UPDATE OF full_name ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION normalize_full_name();
