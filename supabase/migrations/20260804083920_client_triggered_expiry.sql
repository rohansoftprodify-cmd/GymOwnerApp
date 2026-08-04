-- Grant execute permission to authenticated users so the client app can trigger auto-expiry updates.
grant execute on function public.auto_expire_subscriptions() to authenticated;
