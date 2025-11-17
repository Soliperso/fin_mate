-- ============================================================================
-- Migration 31: Add subscription tier and enable documents feature
-- ============================================================================

-- Add subscription_tier column to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'freemium'
CHECK (subscription_tier IN ('freemium', 'premium'));

-- Create index for subscription queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_tier ON public.user_profiles(subscription_tier);

-- ============================================================================
-- Create documents storage bucket
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- Storage policies for documents bucket
-- ============================================================================

-- Users can upload their own documents
DROP POLICY IF EXISTS "Users can upload their own documents" ON storage.objects;
CREATE POLICY "Users can upload their own documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own documents
DROP POLICY IF EXISTS "Users can view their own documents" ON storage.objects;
CREATE POLICY "Users can view their own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own documents
DROP POLICY IF EXISTS "Users can delete their own documents" ON storage.objects;
CREATE POLICY "Users can delete their own documents"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- Helper function to check if user is premium
-- ============================================================================

CREATE OR REPLACE FUNCTION is_user_premium(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 FROM public.user_profiles
    WHERE id = user_id AND subscription_tier = 'premium'
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Migration notes
-- ============================================================================
-- This migration:
-- 1. Adds subscription_tier column to user_profiles (defaults to 'freemium')
-- 2. Creates the documents storage bucket with proper size and file type limits
-- 3. Enables RLS policies for documents bucket
-- 4. Adds helper function to check premium status
