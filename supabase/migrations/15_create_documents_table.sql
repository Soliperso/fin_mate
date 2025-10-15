-- Migration: Create documents table for receipt storage and tax records
-- Description: Allows users to upload receipts, invoices, and tax documents

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

    -- Document metadata
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL, -- 'receipt', 'invoice', 'tax_document', 'other'
    file_size BIGINT NOT NULL, -- in bytes
    mime_type TEXT NOT NULL, -- e.g., 'image/jpeg', 'application/pdf'
    storage_path TEXT NOT NULL, -- path in Supabase Storage

    -- Document details
    title TEXT,
    description TEXT,
    category TEXT, -- Optional category for organization
    amount DECIMAL(15, 2), -- Associated amount if applicable
    document_date DATE, -- Date on the document (e.g., receipt date)

    -- Tax-related fields
    tax_year INTEGER, -- Year for tax purposes
    tax_category TEXT, -- 'income', 'expense', 'deduction', 'other'
    is_tax_deductible BOOLEAN DEFAULT false,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Indexes
    CONSTRAINT documents_user_id_idx CHECK (user_id IS NOT NULL),
    CONSTRAINT documents_file_size_check CHECK (file_size > 0),
    CONSTRAINT documents_file_type_check CHECK (file_type IN ('receipt', 'invoice', 'tax_document', 'other'))
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_transaction_id ON documents(transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_documents_tax_year ON documents(tax_year) WHERE tax_year IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_documents_document_date ON documents(document_date);
CREATE INDEX IF NOT EXISTS idx_documents_file_type ON documents(file_type);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at DESC);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER documents_updated_at_trigger
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_documents_updated_at();

-- Row Level Security (RLS) Policies
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can view their own documents
CREATE POLICY documents_select_policy ON documents
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own documents
CREATE POLICY documents_insert_policy ON documents
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own documents
CREATE POLICY documents_update_policy ON documents
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own documents
CREATE POLICY documents_delete_policy ON documents
    FOR DELETE
    USING (auth.uid() = user_id);

-- Admin policy for viewing all documents
CREATE POLICY documents_admin_select_policy ON documents
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_profiles.id = auth.uid()
            AND user_profiles.role = 'admin'
        )
    );

-- Grant permissions
GRANT ALL ON documents TO authenticated;

-- Comments for documentation
COMMENT ON TABLE documents IS 'Stores user documents including receipts, invoices, and tax records';
COMMENT ON COLUMN documents.file_type IS 'Type of document: receipt, invoice, tax_document, or other';
COMMENT ON COLUMN documents.storage_path IS 'Path to file in Supabase Storage bucket';
COMMENT ON COLUMN documents.tax_year IS 'Tax year for filtering and organization';
COMMENT ON COLUMN documents.is_tax_deductible IS 'Whether this expense is tax deductible';

-- Create storage bucket for documents (run this in Supabase Dashboard or via API)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('documents', 'documents', false);

-- Storage policies (to be applied in Supabase Dashboard)
-- CREATE POLICY "Users can upload their own documents"
-- ON storage.objects FOR INSERT
-- WITH CHECK (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Users can view their own documents"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Users can delete their own documents"
-- ON storage.objects FOR DELETE
-- USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);
