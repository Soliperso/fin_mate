-- Add Rent as a separate default expense category
INSERT INTO public.categories (id, user_id, name, type, icon, color, is_default)
VALUES ('11111111-1111-1111-1111-111111111211'::UUID, NULL, 'Rent', 'expense', '🏠', '#95A5A6', TRUE)
ON CONFLICT (id) DO NOTHING;
