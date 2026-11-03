-- Fonksiyonları giriş yapmamış kullanıcılara kapat; tetikleyici fonksiyonu tamamen kapat.
revoke execute on function public.is_member(uuid) from public, anon;
revoke execute on function public.has_role(uuid, public.member_role[]) from public, anon;
revoke execute on function public.create_company(text) from public, anon;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.is_member(uuid) to authenticated;
grant execute on function public.has_role(uuid, public.member_role[]) to authenticated;
grant execute on function public.create_company(text) to authenticated;
