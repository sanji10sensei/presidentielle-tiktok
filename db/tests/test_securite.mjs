// Vérifie que la clé publique de Supabase (rôle anon) ne peut ni lire ni écrire.
// Simule les rôles et droits par défaut de Supabase sur PGlite.
// Usage, depuis la racine du dépôt :
//   npm install --no-save @electric-sql/pglite@0.2.17
//   node db/tests/test_securite.mjs
// Toute ligne ÉCHEC signale une fuite d'accès.
import { PGlite } from '@electric-sql/pglite'; import fs from 'fs';
const db = new PGlite(); const R=process.argv[2] ?? '.'; const f=p=>fs.readFileSync(R+'/'+p,'utf8');
// Simule les rôles et les droits par défaut de Supabase
await db.exec(`create role anon; create role authenticated;
 alter default privileges in schema public grant all on tables to anon, authenticated;
 alter default privileges in schema public grant all on sequences to anon, authenticated;
 alter default privileges in schema public grant all on functions to anon, authenticated;
 grant usage on schema public to anon, authenticated;`);
await db.exec('BEGIN;'+f('db/installation_complete.sql')+'COMMIT;'); console.log('installation : OK');
await db.exec(f('db/installation_complete.sql').split('-- ==================== db/migrations/004')[1].split('\n').slice(1).join('\n')); console.log('004 rejouée : OK');
await db.exec(f('db/donnees_initiales.sql')); console.log('données initiales : OK');
for (const q of ['select count(*) from candidats','select count(*) from v_suivi_collecte','select count(*) from v_positions_publiables',"insert into themes(slug,libelle) values ('x','x')"]) {
  try { await db.exec('set role anon;'); const r=await db.query(q); console.log('ÉCHEC anon a pu :', q, JSON.stringify(r.rows)); } catch(e){ console.log('REFUS attendu anon :', q, '→', e.message); } finally { await db.exec('reset role;'); }
}
console.log('propriétaire voit :', (await db.query('select count(*)::int n from candidats')).rows[0].n, 'candidats');
