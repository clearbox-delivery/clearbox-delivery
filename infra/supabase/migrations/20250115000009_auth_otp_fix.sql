-- Align OTP RPCs to legacy otp_rate_limits schema (identifier, attempt_count, last_attempt_at)
-- Keep otp_codes as created in 20250115000008_auth_otp.sql

create or replace function public._inc_otp_attempt(p_device_id text, p_otp_type text)
returns void as $$
begin
  insert into public.otp_rate_limits(identifier, attempt_count, last_attempt_at)
  values (p_device_id, 1, now())
  on conflict (identifier)
  do update set attempt_count = public.otp_rate_limits.attempt_count + 1,
                last_attempt_at = now();
end;
$$ language plpgsql security definer;

create or replace function public.send_otp(p_identifier text, p_otp_type text, p_device_id text)
returns jsonb as $$
declare
  v_code text;
  v_cooldown int := case when p_otp_type = 'EMAIL' then 30 else 120 end; -- seconds
  v_max_attempts int := case when p_otp_type = 'EMAIL' then 20 else 5 end;
  v_attempts int := 0;
begin
  -- read legacy rate limit by device_id stored in identifier column
  select attempt_count into v_attempts from public.otp_rate_limits where identifier = p_device_id;

  if coalesce(v_attempts,0) >= v_max_attempts then
    return jsonb_build_object('success', false, 'remaining_attempts', 0, 'error', 'RATE_LIMIT');
  end if;

  perform public._inc_otp_attempt(p_device_id, p_otp_type);

  v_code := lpad(floor(random() * 1000000)::text, 6, '0');
  insert into public.otp_codes(identifier, otp_type, device_id, code, expires_at)
  values (p_identifier, p_otp_type, p_device_id, v_code, now() + interval '10 minutes');

  return jsonb_build_object(
    'success', true,
    'remaining_attempts', greatest(v_max_attempts - coalesce(v_attempts,0) - 1, 0),
    'cooldown_seconds', v_cooldown
  );
end;
$$ language plpgsql security definer;

grant execute on function public.send_otp(text, text, text) to anon, authenticated;
grant execute on function public._inc_otp_attempt(text, text) to anon, authenticated;


