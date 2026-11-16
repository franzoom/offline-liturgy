// Vérifie pruneUnavailableLocations() : un nœud de localisation sans id dans
// l'ensemble fourni (validated_locations.json en pratique — voir
// scripts/make_index.py et CLAUDE.md, "Location picker (locationTree)
// pruning") n'a aucune donnée exploitable, à moins qu'un de ses descendants
// en ait.

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

    test('keeps a diocese with no own folder once validated externally', () {
      // basel.yaml has no sanctoral/basel/ folder — it only overrides an
      // inherited feast's precedence via move:/feasts:. Whether that
      // qualifies is decided by scripts/make_index.py, not by this
      // function: here it only has to honor whatever set it is given.
      final tree = [
        _node(_location('switzerland', LocationGeography.country), [
          _node(_location('basel', LocationGeography.diocese)),
        ]),
      ];

      final pruned = pruneUnavailableLocations(tree, {'switzerland', 'basel'});

      expect(pruned.single.children.map((n) => n.location.id), ['basel']);
    });
  });
}
