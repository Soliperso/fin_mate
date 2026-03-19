-- Migration 46: Auto Backup Storage Bucket
-- Creates a private per-user Supabase Storage bucket for JSON backups

INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', false)
ON CONFLICT DO NOTHING;

-- Each user can only read/write inside their own folder (userId/*)
CREATE POLICY "Users access own backups"
ON storage.objects FOR ALL
USING (
    bucket_id = 'backups'
    AND auth.uid()::text = (storage.foldername(name))[1]
);
