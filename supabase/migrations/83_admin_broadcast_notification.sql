-- Admin broadcast notification function
-- Inserts a notification row for every user in the system.
-- Security definer so it runs with elevated privileges,
-- but guards against non-admin callers before doing anything.
create or replace function admin_broadcast_notification(
  p_title text,
  p_body  text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from user_profiles
    where id = auth.uid() and role = 'admin'
  ) then
    raise exception 'Unauthorized: admin access required';
  end if;

  insert into notifications (user_id, title, message, type, is_read)
  select
    id,
    p_title,
    p_body,
    'system_message',
    false
  from user_profiles;
end;
$$;

grant execute on function admin_broadcast_notification(text, text) to authenticated;
