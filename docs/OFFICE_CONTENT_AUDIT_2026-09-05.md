# Office content audit — reste à traiter

`dart test test/office_content_coverage_test.dart -r expanded`

Mis à jour le 2026-09-07 — 29 anomalies restantes (contre 814 au premier passage), 3283 offices vérifiés (Lyon, 2026). Un autre processus corrige des contenus en parallèle : ce compte est un instantané, pas une valeur stable.

## Semaine sainte

- [ ] Dimanche des Rameaux (29 mars, `PROCESSION_WITH_PALMS`) — prière sur les offrandes, antienne et prière après communion absentes.
- [ ] Vendredi Saint (3 avril, Célébration de la Passion) — antienne d'entrée, prière sur les offrandes, antienne et prière après communion absentes.
- [ ] Vigile pascale (5 avril, `EASTER_VIGIL`) — antienne d'entrée et collecte absentes.

## Commémoraison de tous les fidèles défunts

- [ ] Ières Vêpres (1^er nov.) — entièrement vides.
- [ ] Les 3 messes du 2 nov. — lectures absentes (cycle courant et cycle 1) ; le reste de la messe est désormais complet.

## Cas isolés

- [ ] Dimanche de Pâques (Lectures) — psalmodie, lecture biblique, lecture patristique absentes.
- [ ] Mercredi de la 6^e semaine du Temps pascal (13 mai, Vêpres II, `[non célébrable]`) — lecture brève, répons absents.
- [ ] Jeudi 24 décembre (Vêpres II, `[non célébrable]`) — lecture brève, répons, antienne du Magnificat, intercessions absents.

## Résolu depuis le dernier passage

Mardi/Mercredi Saint (messe), Saint François de Paule, Saint Nizier, 3^e dimanche de Carême (lecture patristique), Nativité de la Vierge Marie (antiennes `PSALM_23`/`PSALM_86`), vendredi et samedi après l'Épiphanie (oraison des Laudes), Assomption (antienne de l'invitatoire), 4^e dimanche de l'Avent — 20 décembre (antienne du Magnificat), Jeudi Saint au soir — plus plusieurs champs de messe déjà comblés pour la Toussaint des défunts et le Vendredi Saint (collecte).

Lundi Saint — Ières Vêpres : ce n'était pas un trou de contenu mais un faux candidat. `vespersDetection` proposait à tort des « Vêpres I » pour le Lundi, Mardi et Mercredi saints (précédence 2, code férial `lent_6_1/2/3`) chaque fois que la veille était un dimanche — alors que ces jours n'ont pas de Vêpres I : c'est la Seconde Vêpres du dimanche des Rameaux qui couvre ce soir-là. Corrigé dans `vespers_detection.dart` (condition 3 du filtre de premières vêpres, ajout de la garde `!ferialDayCheck`).

Trous de cycle lectionnaire (évangile) — Lundi de la 5^e semaine de Carême / Saint Turibio, Lundi de la 4^e semaine du Temps pascal : même cause que le bug d'affichage signalé sur `lent_5_1` (voir ce fichier) — `massExport` ne comparait les tags de cycle qu'à une seule clé (I/II en semaine, A/B/C le dimanche), alors que certains évangiles de semaine (dont celui-ci) sont volontairement tagués A/B/C pour éviter de répéter l'évangile du dimanche voisin. Corrigé dans `mass_export.dart` : un jour de semaine vérifie désormais les deux systèmes de cycle.

Saint Isidore, Saint Matthias, Sainte Cécile, Saint Vincent Ferrier, Saint Stanislas, Saint Jean-Baptiste de la Salle, Mardi dans l'octave de Pâques : ce n'étaient pas des trous de contenu — ces mémoires/fêtes tombent des années où elles sont entièrement supplantées par le Samedi Saint, l'Ascension ou le Christ Roi (précédence ≤ 3, Triduum/solennité/dimanche privilégié). Le Missel les supprime purement et simplement cette année-là, elles ne devraient même pas apparaître comme option « non célébrée » à parcourir — `detectCelebrations()` les renvoyait quand même. Corrigé dans `office_detection.dart` : une célébration dont la précédence est strictement supérieure à `bestPrecedence` quand `bestPrecedence <= 3` n'est plus renvoyée du tout (les égalités de rang restent visibles).
