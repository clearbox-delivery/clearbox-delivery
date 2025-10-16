-- OTP tables and RPCs
-- Tables
create table if not exists public.otp_rate_limits (
  device_id text primary key,
  otp_type text not null check (otp_type in ('EMAIL','PHONE')),
  attempts_count int not null default 0,
  last_attempt_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.otp_codes (
  id uuid primary key default gen_random_uuid(),
  identifier text not null, -- email or phone
  otp_type text not null check (otp_type in ('EMAIL','PHONE')),
  device_id text not null,
  code text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_otp_codes_identifier on public.otp_codes(identifier);
create index if not exists idx_otp_codes_expires on public.otp_codes(expires_at);

-- RLS (minimal: allow authenticated CRUD on own identifiers; relax for MVP)
alter table public.otp_rate_limits enable row level security;
alter table public.otp_codes enable row level security;

create policy otp_rate_limits_rw on public.otp_rate_limits
  for all using (true) with check (true);

create policy otp_codes_rw on public.otp_codes
  for all using (true) with check (true);

-- Helper: upsert rate limit
create or replace function public._inc_otp_attempt(p_device_id text, p_otp_type text)
returns void as $$
begin
  insert into public.otp_rate_limits(device_id, otp_type, attempts_count, last_attempt_at)
  values (p_device_id, p_otp_type, 1, now())
  on conflict (device_id)
  do update set attempts_count = public.otp_rate_limits.attempts_count + 1,
                last_attempt_at = now(),
                updated_at = now();
end;
$$ language plpgsql security definer;

-- RPC: send_otp
create or replace function public.send_otp(p_identifier text, p_otp_type text, p_device_id text)
returns jsonb as $$
declare
  v_code text;
  v_cooldown int := case when p_otp_type = 'EMAIL' then 30 else 120 end; -- seconds
  v_max_attempts int := case when p_otp_type = 'EMAIL' then 20 else 5 end;
  v_rl record;
begin
  select * into v_rl from public.otp_rate_limits where device_id = p_device_id;

  if v_rl.attempts_count is not null and v_rl.attempts_count >= v_max_attempts then
    return jsonb_build_object('success', false, 'remaining_attempts', 0, 'error', 'RATE_LIMIT');
  end if;

  perform public._inc_otp_attempt(p_device_id, p_otp_type);

  v_code := lpad(floor(random() * 1000000)::text, 6, '0');
  insert into public.otp_codes(identifier, otp_type, device_id, code, expires_at)
  values (p_identifier, p_otp_type, p_device_id, v_code, now() + interval '10 minutes');

  -- MVP: 不實際寄送，僅返回 success 與剩餘次數；實際環境請用 Edge Function 發信/簡訊
  return jsonb_build_object('success', true, 'remaining_attempts', greatest(v_max_attempts - coalesce(v_rl.attempts_count,0) - 1,0), 'cooldown_seconds', v_cooldown);
end;
$$ language plpgsql security definer;

-- RPC: verify_otp
create or replace function public.verify_otp(p_identifier text, p_otp_code text, p_otp_type text, p_device_id text)
returns jsonb as $$
declare
  v_row public.otp_codes;
begin
  select * into v_row
  from public.otp_codes
  where identifier = p_identifier and otp_type = p_otp_type and code = p_otp_code
  order by created_at desc limit 1;

  if v_row.id is null then
    return jsonb_build_object('verified', false, 'error', 'NOT_FOUND');
  end if;

  if now() > v_row.expires_at then
    return jsonb_build_object('verified', false, 'error', 'EXPIRED');
  end if;

  -- optional: consume code
  delete from public.otp_codes where id = v_row.id;

  return jsonb_build_object('verified', true);
end;
$$ language plpgsql security definer;

grant execute on function public.send_otp(text, text, text) to anon, authenticated;
grant execute on function public.verify_otp(text, text, text, text) to anon, authenticated;


