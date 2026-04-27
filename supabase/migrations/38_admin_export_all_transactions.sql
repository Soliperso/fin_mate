create or replace function admin_export_all_transactions()
returns table (
  date        text,
  type        text,
  amount      text,
  account     text,
  category    text,
  description text,
  notes       text,
  tags        text,
  user_id     text
)
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

  return query
  select
    t.date::text,
    t.type::text,
    t.amount::text,
    coalesce(a.name, ''),
    coalesce(c.name, ''),
    coalesce(t.description, ''),
    coalesce(t.notes, ''),
    coalesce(array_to_string(t.tags, ';'), ''),
    t.user_id::text
  from transactions t
  left join accounts a on a.id = t.account_id
  left join categories c on c.id = t.category_id
  order by t.date desc;
end;
$$;

grant execute on function admin_export_all_transactions() to authenticated;
