-- Migration 93: AI security hardening.
--
-- Adds atomic per-user enforcement of:
--   1. Sliding-window QPS (60 requests / 60 seconds)
--   2. Free-tier lifetime cap (10 queries) — delegates to existing free_uses_count
--   3. Daily $ ceiling (50 cents/user/day = ~833 messages of gpt-4o-mini)
--
-- The openai-proxy edge function calls try_consume_ai_budget() once per request
-- before forwarding to OpenAI. Failure modes are mapped to client-facing codes:
--   - rate_limited    → too many requests
--   - quota_exceeded  → free-tier 10/lifetime hit
--   - daily_cap       → premium user's per-day dollar ceiling hit
--
-- Why two tables:
--   - ai_request_log    : sliding-window log, frequently pruned
--   - ai_daily_spend    : daily cost ledger, idempotent UPSERT per (user, day)
--
-- Existing migration 89's try_consume_ai_query() is retained as a fallback /
-- legacy entry point. The new RPC supersedes it in the edge function.

-- ── ai_daily_spend ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.ai_daily_spend (
  user_id     UUID    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day         DATE    NOT NULL DEFAULT CURRENT_DATE,
  tokens_in   INTEGER NOT NULL DEFAULT 0,
  tokens_out  INTEGER NOT NULL DEFAULT 0,
  cents_spent INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, day)
);

ALTER TABLE public.ai_daily_spend ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own AI spend" ON public.ai_daily_spend;
CREATE POLICY "Users can view own AI spend"
  ON public.ai_daily_spend FOR SELECT
  USING (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE policies for clients — only SECURITY DEFINER RPCs write.

-- ── ai_request_log ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.ai_request_log (
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_request_log_user_time
  ON public.ai_request_log(user_id, requested_at DESC);

ALTER TABLE public.ai_request_log ENABLE ROW LEVEL SECURITY;

-- No client access at all. Only the SECURITY DEFINER RPC reads/writes.

-- ── try_consume_ai_budget ────────────────────────────────────────────────────
-- Single atomic gate for all AI requests.
-- Returns one row:
--   allowed BOOLEAN          : true → request may proceed
--   reason  TEXT             : null on success; 'rate_limited' | 'quota_exceeded' | 'daily_cap' on failure
--   remaining_cents INTEGER  : informational; remaining daily budget (0 if exhausted)

DROP FUNCTION IF EXISTS public.try_consume_ai_budget(UUID, INTEGER);

CREATE OR REPLACE FUNCTION public.try_consume_ai_budget(
  p_user_id                 UUID,
  p_estimated_input_tokens  INTEGER
)
RETURNS TABLE (
  allowed         BOOLEAN,
  reason          TEXT,
  remaining_cents INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_tier               TEXT;
  v_free_uses          INTEGER;
  v_qps_count          INTEGER;
  v_today_cents        INTEGER;
  v_estimated_cents    INTEGER;

  -- Tunables (all hardcoded — server-controlled, not client-supplied)
  c_qps_window_seconds CONSTANT INTEGER := 60;
  c_qps_limit          CONSTANT INTEGER := 60;
  c_daily_cap_cents    CONSTANT INTEGER := 50;     -- $0.50 / user / day
  c_free_lifetime_cap  CONSTANT INTEGER := 10;
  -- gpt-4o-mini pricing (cents per 1M tokens): input 15, output 60. max_tokens=400.
  -- Per-1K factors keep arithmetic in integers.
  c_input_cents_per_1k  CONSTANT NUMERIC := 0.015;
  c_output_cents_per_1k CONSTANT NUMERIC := 0.060;
  c_max_output_tokens   CONSTANT INTEGER := 400;
BEGIN
  -- Authorise: callers can only consume their own budget.
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Forbidden: budget consumption requires matching auth.uid()';
  END IF;

  -- ── 1. QPS check (sliding 60s window) ─────────────────────────────────────
  SELECT COUNT(*)::INTEGER
    INTO v_qps_count
    FROM public.ai_request_log
   WHERE user_id = p_user_id
     AND requested_at > NOW() - (c_qps_window_seconds || ' seconds')::INTERVAL;

  IF v_qps_count >= c_qps_limit THEN
    RETURN QUERY SELECT FALSE, 'rate_limited'::TEXT, 0;
    RETURN;
  END IF;

  -- ── 2. Look up subscription tier + free_uses_count atomically ─────────────
  SELECT subscription_tier, COALESCE(free_uses_count, 0)
    INTO v_tier, v_free_uses
    FROM public.user_profiles
   WHERE id = p_user_id
   FOR UPDATE;

  IF NOT FOUND THEN
    -- No profile row → treat as freemium with zero uses
    v_tier := 'freemium';
    v_free_uses := 0;
  END IF;

  -- ── 3. Free-tier lifetime cap ─────────────────────────────────────────────
  IF v_tier <> 'premium' AND v_free_uses >= c_free_lifetime_cap THEN
    RETURN QUERY SELECT FALSE, 'quota_exceeded'::TEXT, 0;
    RETURN;
  END IF;

  -- ── 4. Daily cost ceiling — read today's row with FOR UPDATE ─────────────
  SELECT cents_spent
    INTO v_today_cents
    FROM public.ai_daily_spend
   WHERE user_id = p_user_id
     AND day = CURRENT_DATE
   FOR UPDATE;

  IF v_today_cents IS NULL THEN
    v_today_cents := 0;
  END IF;

  -- Pre-charge: input estimate + worst-case output (max_tokens)
  v_estimated_cents := CEIL(
    (p_estimated_input_tokens::NUMERIC / 1000.0) * c_input_cents_per_1k
    + (c_max_output_tokens::NUMERIC      / 1000.0) * c_output_cents_per_1k
  )::INTEGER;
  IF v_estimated_cents < 1 THEN
    v_estimated_cents := 1; -- never charge 0; smallest unit is 1 cent
  END IF;

  IF v_today_cents >= c_daily_cap_cents THEN
    RETURN QUERY SELECT FALSE, 'daily_cap'::TEXT, 0;
    RETURN;
  END IF;

  -- ── 5. Reserve budget ─────────────────────────────────────────────────────
  INSERT INTO public.ai_request_log(user_id) VALUES (p_user_id);

  INSERT INTO public.ai_daily_spend(user_id, day, tokens_in, cents_spent)
  VALUES (p_user_id, CURRENT_DATE, p_estimated_input_tokens, v_estimated_cents)
  ON CONFLICT (user_id, day) DO UPDATE
     SET tokens_in   = public.ai_daily_spend.tokens_in   + EXCLUDED.tokens_in,
         cents_spent = public.ai_daily_spend.cents_spent + EXCLUDED.cents_spent;

  -- ── 6. Free-tier counter — increment if not premium ──────────────────────
  IF v_tier <> 'premium' THEN
    UPDATE public.user_profiles
       SET free_uses_count = COALESCE(free_uses_count, 0) + 1
     WHERE id = p_user_id;
  END IF;

  -- ── 7. Opportunistic prune (cheap; runs on ~1/100 calls) ──────────────────
  IF (random() < 0.01) THEN
    DELETE FROM public.ai_request_log
     WHERE requested_at < NOW() - INTERVAL '5 minutes';
  END IF;

  RETURN QUERY SELECT
    TRUE,
    NULL::TEXT,
    GREATEST(c_daily_cap_cents - (v_today_cents + v_estimated_cents), 0);
END;
$$;

REVOKE ALL ON FUNCTION public.try_consume_ai_budget(UUID, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.try_consume_ai_budget(UUID, INTEGER) TO authenticated;
