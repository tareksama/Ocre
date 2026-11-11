-- =====================================================================
--  Suivi Dofus Ocre – échanges d'archimonstres
--  À coller une seule fois dans Supabase : SQL Editor → New query → Run
--  (le script peut être relancé sans risque)
-- =====================================================================

-- ---------- Comptes (pseudo public) ----------
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text not null check (username ~ '^[^[:space:]@<>"''/\\]{3,20}$'),
  created_at timestamptz not null default now()
);
create unique index if not exists profiles_username_lower on public.profiles (lower(username));

-- ---------- Personnages Dofus Touch ----------
create table if not exists public.characters (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name       text not null check (char_length(btrim(name)) between 2 and 30),
  server     text not null check (char_length(btrim(server)) between 2 and 30),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists characters_owner_server_name on public.characters (owner, lower(server), lower(name));
create index if not exists characters_server on public.characters (lower(server));

-- ---------- Archis proposés (offer) / recherchés (want) ----------
create table if not exists public.character_archis (
  character_id uuid not null references public.characters(id) on delete cascade,
  archi_id     integer not null check (archi_id between 1 and 99999),
  kind         text not null check (kind in ('offer','want')),
  created_at   timestamptz not null default now(),
  primary key (character_id, kind, archi_id)
);
create index if not exists character_archis_archi on public.character_archis (archi_id, kind);

-- ---------- Création automatique du profil à l'inscription ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(nullif(btrim(new.raw_user_meta_data->>'username'), ''),
                           'joueur_' || substr(new.id::text, 1, 8)));
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Limite : 20 personnages par compte ----------
create or replace function public.limit_characters()
returns trigger language plpgsql as $$
begin
  if (select count(*) from public.characters where owner = new.owner) >= 20 then
    raise exception 'Maximum 20 personnages par compte';
  end if;
  return new;
end $$;
drop trigger if exists characters_limit on public.characters;
create trigger characters_limit before insert on public.characters
  for each row execute function public.limit_characters();

-- ---------- Date de dernière mise à jour des listes ----------
create or replace function public.touch_character()
returns trigger language plpgsql as $$
begin
  update public.characters set updated_at = now()
   where id = coalesce(new.character_id, old.character_id);
  return null;
end $$;
drop trigger if exists character_archis_touch on public.character_archis;
create trigger character_archis_touch after insert or delete on public.character_archis
  for each row execute function public.touch_character();

-- ---------- Sécurité (Row Level Security) ----------
alter table public.profiles         enable row level security;
alter table public.characters       enable row level security;
alter table public.character_archis enable row level security;

revoke all on public.profiles, public.characters, public.character_archis from anon;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.characters, public.character_archis to authenticated;

drop policy if exists "profils lisibles" on public.profiles;
create policy "profils lisibles" on public.profiles for select to authenticated using (true);

drop policy if exists "persos lisibles" on public.characters;
create policy "persos lisibles" on public.characters for select to authenticated using (true);
drop policy if exists "persos ajout" on public.characters;
create policy "persos ajout" on public.characters for insert to authenticated with check (owner = auth.uid());
drop policy if exists "persos modif" on public.characters;
create policy "persos modif" on public.characters for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
drop policy if exists "persos suppr" on public.characters;
create policy "persos suppr" on public.characters for delete to authenticated using (owner = auth.uid());

drop policy if exists "listes lisibles" on public.character_archis;
create policy "listes lisibles" on public.character_archis for select to authenticated using (true);
drop policy if exists "listes ajout" on public.character_archis;
create policy "listes ajout" on public.character_archis for insert to authenticated
  with check (exists (select 1 from public.characters c where c.id = character_id and c.owner = auth.uid()));
drop policy if exists "listes suppr" on public.character_archis;
create policy "listes suppr" on public.character_archis for delete to authenticated
  using (exists (select 1 from public.characters c where c.id = character_id and c.owner = auth.uid()));

-- ---------- Fonctions appelées par l'application ----------

-- Pseudo libre ? (utilisé à l'inscription, avant d'être connecté)
create or replace function public.username_available(u text)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(btrim(u)));
$$;
revoke all on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;

-- Échanges possibles pour un de MES persos, sur son serveur (ou p_server) :
--  kind = 'offer' : l'autre perso propose un archi que je recherche
--  kind = 'want'  : l'autre perso recherche un archi que je propose
drop function if exists public.trade_matches(uuid);
create or replace function public.trade_matches(p_char uuid, p_server text default null)
returns table (character_id uuid, name text, server text, username text,
               archi_id integer, kind text, updated_at timestamptz)
language sql stable set search_path = public as $$
  select o.id, o.name, o.server, p.username, ca.archi_id, ca.kind, o.updated_at
  from public.characters me
  join public.characters o on lower(o.server) = lower(coalesce(nullif(btrim(p_server), ''), me.server))
                         and o.owner <> me.owner
  join public.profiles p on p.id = o.owner
  join public.character_archis ca on ca.character_id = o.id
  join public.character_archis mine on mine.character_id = me.id
       and mine.archi_id = ca.archi_id
       and mine.kind = case ca.kind when 'offer' then 'want' else 'offer' end
  where me.id = p_char and me.owner = auth.uid()
  order by o.updated_at desc;
$$;
revoke all on function public.trade_matches(uuid, text) from public;
grant execute on function public.trade_matches(uuid, text) to authenticated;

-- Qui propose / recherche un archi donné sur un serveur
create or replace function public.who_has(p_server text, p_archi integer)
returns table (character_id uuid, name text, server text, username text,
               kind text, mine boolean, updated_at timestamptz)
language sql stable set search_path = public as $$
  select o.id, o.name, o.server, p.username, ca.kind, o.owner = auth.uid(), o.updated_at
  from public.character_archis ca
  join public.characters o on o.id = ca.character_id
  join public.profiles p on p.id = o.owner
  where ca.archi_id = p_archi and lower(o.server) = lower(btrim(p_server))
  order by o.updated_at desc
  limit 200;
$$;
revoke all on function public.who_has(text, integer) from public;
grant execute on function public.who_has(text, integer) to authenticated;

-- Serveurs déjà utilisés (pour les suggestions)
create or replace function public.trade_servers()
returns table (server text, characters bigint)
language sql stable set search_path = public as $$
  select min(server), count(*) from public.characters group by lower(server) order by count(*) desc;
$$;
revoke all on function public.trade_servers() from public;
grant execute on function public.trade_servers() to authenticated;
