-- Admin RPCs for managing system-wide default categories
-- All functions use SECURITY DEFINER and verify the caller is an admin.

CREATE OR REPLACE FUNCTION admin_get_default_categories()
RETURNS TABLE (
  id UUID,
  name TEXT,
  type TEXT,
  icon TEXT,
  color TEXT,
  is_default BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
    SELECT c.id, c.name, c.type, c.icon, c.color, c.is_default, c.created_at
    FROM categories c
    WHERE c.is_default = TRUE AND c.user_id IS NULL
    ORDER BY c.type, c.name;
END;
$$;

CREATE OR REPLACE FUNCTION admin_add_default_category(
  p_name  TEXT,
  p_type  TEXT,
  p_icon  TEXT,
  p_color TEXT
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id UUID;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  INSERT INTO categories (name, type, icon, color, is_default, user_id)
  VALUES (p_name, p_type, p_icon, p_color, TRUE, NULL)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION admin_update_default_category(
  p_id    UUID,
  p_name  TEXT,
  p_icon  TEXT,
  p_color TEXT
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE categories
  SET name = p_name, icon = p_icon, color = p_color
  WHERE id = p_id AND is_default = TRUE AND user_id IS NULL;
END;
$$;

CREATE OR REPLACE FUNCTION admin_delete_default_category(p_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM categories WHERE id = p_id AND is_default = TRUE AND user_id IS NULL;
END;
$$;
