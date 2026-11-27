// Test du schéma et des migrations sur une base PostgreSQL embarquée (PGlite, sans serveur).
// Usage, depuis la racine du dépôt :
//   npm install --no-save @electric-sql/pglite@0.2.17
//   node db/tests/test_migrations.mjs
// Chaque ligne affiche OK, ou REFUS attendu pour un garde-fou ; toute ligne ÉCHEC est une régression.
import { PGlite } from '@electric-sql/pglite';
import fs from 'fs';
const R = process.argv[2] ?? '.';
const db = new PGlite();
const f = p => fs.readFileSync(`${R}/${p}`, 'utf8');
const ok = async (label, sql) => { try { await db.exec(sql); console.log('OK   ', label); } catch (e) { console.log('ÉCHEC', label, '→', e.message); } };
const ko = async (label, sql) => { try { await db.exec(sql); console.log('ÉCHEC (aurait dû être refusé)', label); } catch (e) { console.log('REFUS attendu', label, '→', e.message); } };
await ok('schéma', f('db/schema_presidentielle.sql'));
await ko('statut ambition_annoncee avant 001', "insert into candidats(slug,nom,statut) values('t0','T','ambition_annoncee')");
for (const m of ['001_statuts_candidats','002_suivi_programmes','003_garde_fous']) { await ok(m, f(`db/migrations/${m}.sql`)); await ok(m+' rejouée', f(`db/migrations/${m}.sql`)); }
await ok('données', `
insert into candidats(slug,nom,statut,dans_le_panel) values ('a','A','declare',true),('b','B','declare',false),('d','D','declare_peu_visible',false),('t','T','ambition_annoncee',false);
insert into themes(slug,libelle) values ('retraites','Retraites'),('logement','Logement');
insert into sources(url,type,editeur,publiee_le,niveau_fiabilite) values ('u1','programme','A',current_date,1),('u3','reseau_social','X',current_date,3),('u2','presse','P',current_date,1);
insert into positions(candidat_id,theme_id,source_id,resume_neutre,valide_depuis) values (1,1,1,'r',current_date),(1,1,2,'r',current_date),(2,1,1,'r',current_date),(1,2,1,'r',current_date);
update positions set statut='verifie',verifie_par='ed',verifie_le=now() where id=1;
update positions set statut='verifie',verifie_par='ed',verifie_le=now(),valide_jusqu_a=current_date-1 where id=4;
update positions set statut='verifie',verifie_par='ed',verifie_le=now() where id=3;
insert into videos(format,script) values ('comparateur','{}');`);
await ko('vérifier une position de source niveau 3', "update positions set statut='verifie',verifie_par='ed',verifie_le=now() where id=2");
await ko('déclasser en niveau 3 une source dont dépend une position vérifiée', "update sources set niveau_fiabilite=3 where id=1");
await ok('déclasser une source sans position vérifiée', "update sources set niveau_fiabilite=2 where id=3");
await ok('vidéo : candidat du panel, position vérifiée', "insert into video_affirmations values (1,1,1,5)");
await ko('vidéo : candidat hors panel', "insert into video_affirmations values (1,3,2,5)");
await ko('vidéo : position périmée', "insert into video_affirmations values (1,4,3,5)");
console.log('trous de couverture :', JSON.stringify((await db.query('select * from v_trous_de_couverture')).rows));
console.log('suivi collecte (slugs) :', JSON.stringify([...new Set((await db.query('select slug from v_suivi_collecte')).rows.map(r=>r.slug))]));
