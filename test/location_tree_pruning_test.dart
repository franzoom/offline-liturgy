// Vérifie pruneUnavailableLocations() : un diocèse (ou tout autre nœud de
// localisation) sans dossier sanctoral/<id>/ correspondant n'a aucune donnée
// exploitable — voir CLAUDE.md et lib/classes/location_class.dart pour le
// contexte complet (Location.applyToCalendar préfixe toujours les clés de
// fête par l'id de la localisation, sans repli sur un dossier partagé).

import 'package:test/test.dart';
import 'package:offline_liturgy/offline_liturgy.dart';

Location _location(String id, LocationGeography geography, {String? parent}) {
  return Location(
    id: id,
    language: 'french',
    geography: geography,
    parent: parent,
    frenchName: id,
    frenchLocative: id,
    feasts: const [],
  );
}

LocationNode _node(Location location,
    [List<LocationNode> children = const []]) {
  return LocationNode(location: location, children: children);
}

void main() {
  group('pruneUnavailableLocations', () {
    test('keeps a diocese with its own sanctoral data', () {
      final tree = [_node(_location('lyon', LocationGeography.diocese))];

      final pruned = pruneUnavailableLocations(tree, {'lyon'});

      expect(pruned.map((n) => n.location.id), ['lyon']);
    });

    test('drops a diocese with no sanctoral data', () {
      final tree = [_node(_location('agen', LocationGeography.diocese))];

      final pruned = pruneUnavailableLocations(tree, {'lyon'});

      expect(pruned, isEmpty);
    });

    test('keeps a country with no own data but a valid diocese child', () {
      final tree = [
        _node(_location('france', LocationGeography.country), [
          _node(_location('lyon', LocationGeography.diocese)),
          _node(_location('agen', LocationGeography.diocese)),
        ]),
      ];

      final pruned = pruneUnavailableLocations(tree, {'lyon'});

      expect(pruned, hasLength(1));
      expect(pruned.single.location.id, 'france');
      expect(pruned.single.children.map((n) => n.location.id), ['lyon']);
    });

    test('drops a country with no own data and no valid children', () {
      final tree = [
        _node(_location('switzerland', LocationGeography.country)),
        _node(_location('france', LocationGeography.country), [
          _node(_location('lyon', LocationGeography.diocese)),
        ]),
      ];

      final pruned = pruneUnavailableLocations(tree, {'lyon'});

      expect(pruned.map((n) => n.location.id), ['france']);
    });
  });
}
