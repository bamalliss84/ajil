-- =====================================================================
-- تصحيح السحب على صفحات: max_seq يجب أن يكون أعلى مؤشر *مُرجَع* فعلاً،
-- وإلا تُتخطى صفوف عندما تمتلئ الصفحة. نحدد سقفاً موحداً للجداول الثلاثة.
-- =====================================================================
create or replace function app.pull_changes(p_branch uuid, p_since bigint, p_limit int default 500)
returns jsonb
language plpgsql stable security invoker set search_path = app, public as $$
declare
  upper_seq bigint;
begin
  -- الـ p_limit-ـي أصغر مؤشر بعد p_since عبر الجداول الثلاثة
  select s into upper_seq from (
    select server_seq s from app.customers    where branch_id = p_branch and server_seq > p_since
    union all
    select server_seq   from app.transactions where branch_id = p_branch and server_seq > p_since
    union all
    select server_seq   from app.promises     where branch_id = p_branch and server_seq > p_since
  ) x order by s offset greatest(p_limit, 1) - 1 limit 1;
  upper_seq := coalesce(upper_seq, 9223372036854775807);

  return jsonb_build_object(
    'customers', coalesce((select jsonb_agg(c order by c.server_seq) from app.customers c
        where c.branch_id = p_branch and c.server_seq > p_since and c.server_seq <= upper_seq), '[]'),
    'transactions', coalesce((select jsonb_agg(t order by t.server_seq) from app.transactions t
        where t.branch_id = p_branch and t.server_seq > p_since and t.server_seq <= upper_seq), '[]'),
    'promises', coalesce((select jsonb_agg(p order by p.server_seq) from app.promises p
        where p.branch_id = p_branch and p.server_seq > p_since and p.server_seq <= upper_seq), '[]'),
    'max_seq', (select coalesce(max(m), p_since) from (
        select max(server_seq) m from app.customers where branch_id = p_branch and server_seq > p_since and server_seq <= upper_seq
        union all select max(server_seq) from app.transactions where branch_id = p_branch and server_seq > p_since and server_seq <= upper_seq
        union all select max(server_seq) from app.promises where branch_id = p_branch and server_seq > p_since and server_seq <= upper_seq) y)
  );
end $$;
