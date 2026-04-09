-- Migration 52: Add server-side admin verification RPC for client use
-- The client calls this RPC to confirm admin status server-side before
-- rendering admin-only UI. Relies on the existing is_admin() helper.

CREATE OR REPLACE FUNCTION verify_admin_access()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Returns true only if the calling user has role = 'admin' in user_profiles.
  -- SECURITY DEFINER ensures the role column cannot be spoofed client-side.
  RETURN COALESCE(is_admin(), false);
END;
$$;

-- Restrict execute to authenticated users only
REVOKE ALL ON FUNCTION verify_admin_access() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION verify_admin_access() TO authenticated;

-- Enable RLS on analytics_events so admins can see all rows, regular users only their own
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own analytics" ON public.analytics_events;
CREATE POLICY "Users see own analytics" ON public.analytics_events
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Admins see all analytics" ON public.analytics_events;
CREATE POLICY "Admins see all analytics" ON public.analytics_events
  FOR ALL USING (is_admin());
