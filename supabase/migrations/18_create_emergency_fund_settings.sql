-- ============================================================================
-- CREATE EMERGENCY FUND SETTINGS TABLE
-- ============================================================================
-- Allows users to set custom emergency fund targets

CREATE TABLE IF NOT EXISTS public.emergency_fund_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  target_amount DECIMAL(15,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.emergency_fund_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own emergency fund settings" ON public.emergency_fund_settings;
CREATE POLICY "Users can view own emergency fund settings" ON public.emergency_fund_settings
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own emergency fund settings" ON public.emergency_fund_settings;
CREATE POLICY "Users can insert own emergency fund settings" ON public.emergency_fund_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own emergency fund settings" ON public.emergency_fund_settings;
CREATE POLICY "Users can update own emergency fund settings" ON public.emergency_fund_settings
  FOR UPDATE USING (auth.uid() = user_id);
