import 'package:flutter_test/flutter_test.dart';
import 'package:samal_nav/models/transport_catalog.dart';

const _modeIds = [
  'walking',
  'bicycle',
  'motorcycle',
  'car',
  'public_transportation',
  'jeepney',
  'tricycle',
  'multicab',
  'van',
  'bus',
  'ferry',
  'boat',
];

void main() {
  group('TransportCatalog initial registry', () {
    test('contains twelve unique modes and seven unique categories', () {
      final catalog = TransportCatalog.initial;
      expect(catalog.modes.map((mode) => mode.id).toList(), _modeIds);
      expect(catalog.modes.map((mode) => mode.id).toSet(), hasLength(12));
      expect(
        catalog.categories.map((category) => category.id).toSet(),
        hasLength(7),
      );
      expect(catalog.modes.every((mode) => mode.isActive), isTrue);
      expect(catalog.schemaVersion, 1);
      expect(catalog.catalogVersion, 1);
    });

    test('uses the required two-level category hierarchy', () {
      final parents = {
        for (final category in TransportCatalog.initial.categories)
          category.id: category.parentId,
      };
      expect(parents, {
        'land': null,
        'land_non_motorized': 'land',
        'land_motorized': 'land',
        'public_transport': null,
        'public_transport_local': 'public_transport',
        'water': null,
        'water_transfer': 'water',
      });
    });

    test('uses stable lowercase snake_case identifiers', () {
      for (final id in _modeIds) {
        expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue);
      }
    });

    test('requires directed endpoints for ferry and boat only', () {
      for (final mode in TransportCatalog.initial.modes) {
        expect(
          mode.requiresDirectedEndpoints,
          mode.id == 'ferry' || mode.id == 'boat',
          reason: mode.id,
        );
      }
    });

    test('sets independent initial workflow capabilities', () {
      for (final mode in TransportCatalog.initial.modes) {
        expect(mode.workflowCapabilities.profilePreference, isTrue);
        expect(mode.workflowCapabilities.manualLegSelection, isTrue);
        expect(mode.workflowCapabilities.circuitPlanning, isFalse);
        expect(mode.workflowCapabilities.mogaRouteEvaluation, isFalse);
        expect(mode.workflowCapabilities.fixedCommitmentCapture, isTrue);
      }
    });
  });

  group('TransportCatalog validation', () {
    test('rejects non-positive schema and catalog versions', () {
      expect(() => _catalog(schemaVersion: 0), throwsA(isA<FormatException>()));
      expect(
        () => _catalog(catalogVersion: -1),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed and duplicate canonical identifiers', () {
      final valid = TransportCatalog.initial;
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: valid.categories,
          modes: [valid.modes.first, _copyMode(valid.modes.first)],
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: [const TransportCategory(id: 'Bad-ID', labelKey: 'bad')],
          modes: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects missing categories and duplicate aliases', () {
      final valid = TransportCatalog.initial;
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: valid.categories,
          modes: [_copyMode(valid.modes.first, categoryId: 'missing_category')],
        ),
        throwsA(isA<FormatException>()),
      );

      final first = _copyMode(valid.modes.first, aliases: const ['old_walk']);
      final second = _copyMode(valid.modes[1], aliases: const ['old_walk']);
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: valid.categories,
          modes: [first, second],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects aliases that collide with canonical identifiers', () {
      final valid = TransportCatalog.initial;
      final walking = _copyMode(valid.modes.first, aliases: const ['car']);
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: valid.categories,
          modes: [walking, ...valid.modes.skip(1)],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects category cycles, excessive depth, and missing parents', () {
      final valid = TransportCatalog.initial;
      expect(
        () => _catalogWithCategories([
          const TransportCategory(
            id: 'root_a',
            labelKey: 'root_a',
            parentId: 'root_b',
          ),
          const TransportCategory(
            id: 'root_b',
            labelKey: 'root_b',
            parentId: 'root_a',
          ),
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => _catalogWithCategories([
          const TransportCategory(id: 'root', labelKey: 'root'),
          const TransportCategory(
            id: 'child',
            labelKey: 'child',
            parentId: 'root',
          ),
          const TransportCategory(
            id: 'grandchild',
            labelKey: 'grandchild',
            parentId: 'child',
          ),
          const TransportCategory(
            id: 'great_grandchild',
            labelKey: 'great_grandchild',
            parentId: 'grandchild',
          ),
        ]),
        throwsA(isA<FormatException>()),
      );
      expect(valid.categories, isNotEmpty);
    });

    test('rejects endpoint requirements inconsistent with water category', () {
      final valid = TransportCatalog.initial;
      final invalidFerry = _copyMode(
        valid.modes[10],
        requiresDirectedEndpoints: false,
      );
      expect(
        () => TransportCatalog(
          schemaVersion: 1,
          catalogVersion: 1,
          categories: valid.categories,
          modes: [...valid.modes.take(10), invalidFerry, valid.modes.last],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TransportCatalog legacy codec', () {
    test('decodes only the exact approved public transport aliases', () {
      final catalog = TransportCatalog.initial;
      for (final alias in ['public transportation', 'publicTransportation']) {
        final decoded = catalog.decodeMode(alias);
        expect(decoded.modeId, 'public_transportation');
        expect(decoded.isSupported, isTrue);
        expect(decoded.toJson()['modeId'], 'public_transportation');
      }
      for (final nearMiss in [
        ' Public transportation',
        'public transportation ',
        'PUBLIC TRANSPORTATION',
        'PublicTransportation',
      ]) {
        expect(catalog.decodeMode(nearMiss).isSupported, isFalse);
        expect(catalog.decodeMode(nearMiss).modeId, nearMiss);
      }
    });

    test('decodes every canonical mode and encodes canonical identifiers', () {
      final catalog = TransportCatalog.initial;
      for (final id in _modeIds) {
        final reference = catalog.decodeMode(id);
        expect(reference.modeId, id);
        expect(reference.isSupported, isTrue);
        expect(reference.toJson()['modeId'], id);
      }
    });

    test('preserves unknown identifiers and historical labels exactly', () {
      final catalog = TransportCatalog.initial;
      const rawId = 'Legacy Mode/Unknown';
      const label = 'Old locally recorded mode';
      final reference = catalog.decodeMode(rawId, labelSnapshot: label);
      expect(reference.isSupported, isFalse);
      expect(reference.modeId, rawId);
      expect(reference.labelSnapshot, label);
      expect(reference.toJson(), {'modeId': rawId, 'labelSnapshot': label});
      final restored = TransportModeReference.fromJson(
        reference.toJson(),
        catalog,
      );
      expect(restored.modeId, rawId);
      expect(restored.labelSnapshot, label);
      expect(restored.isSupported, isFalse);
    });

    test(
      'preserves an old label independently of the current catalog label',
      () {
        final historical = TransportCatalog.initial.decodeMode(
          'walking',
          labelSnapshot: 'Walk (historic label)',
        );
        final decoded = TransportModeReference.fromJson(
          historical.toJson(),
          TransportCatalog.initial,
        );
        expect(decoded.definition!.labelKey, 'transport.mode.walking');
        expect(decoded.labelSnapshot, 'Walk (historic label)');
      },
    );

    test('keeps inactive known modes readable but not newly selectable', () {
      final initial = TransportCatalog.initial;
      final modes = [
        _copyMode(initial.modes.first, isActive: false),
        ...initial.modes.skip(1),
      ];
      final inactiveCatalog = TransportCatalog(
        schemaVersion: 1,
        catalogVersion: 2,
        categories: initial.categories,
        modes: modes,
      );
      final decoded = inactiveCatalog.decodeMode('walking');
      expect(decoded.isSupported, isTrue);
      expect(decoded.isActive, isFalse);
      expect(decoded.canSelectForNewUse, isFalse);
      expect(inactiveCatalog.selectableMode('walking'), isNull);
      expect(decoded.toJson()['modeId'], 'walking');
      expect(
        decoded.definition!.workflowCapabilities.fixedCommitmentCapture,
        isTrue,
      );
    });

    test('keeps workflow capabilities independent of mode active status', () {
      final capabilities = const WorkflowCapabilities(
        profilePreference: false,
        manualLegSelection: true,
        circuitPlanning: true,
        mogaRouteEvaluation: false,
        fixedCommitmentCapture: true,
      );
      final custom = TransportMode(
        id: 'walk_custom',
        categoryId: 'land_non_motorized',
        labelKey: 'transport.mode.walk_custom',
        isActive: false,
        legacyAliases: const [],
        requiresDirectedEndpoints: false,
        workflowCapabilities: capabilities,
      );
      final catalog = TransportCatalog(
        schemaVersion: 1,
        catalogVersion: 2,
        categories: TransportCatalog.initial.categories,
        modes: [custom],
      );
      final decoded = catalog.decodeMode('walk_custom');
      expect(decoded.canSelectForNewUse, isFalse);
      expect(
        decoded.definition!.workflowCapabilities.profilePreference,
        isFalse,
      );
      expect(
        decoded.definition!.workflowCapabilities.manualLegSelection,
        isTrue,
      );
      expect(decoded.definition!.workflowCapabilities.circuitPlanning, isTrue);
      expect(
        decoded.definition!.workflowCapabilities.mogaRouteEvaluation,
        isFalse,
      );
      expect(
        decoded.definition!.workflowCapabilities.fixedCommitmentCapture,
        isTrue,
      );
    });
  });

  group('TransportCatalog serialization', () {
    test('serializes deterministically and round-trips the registry', () {
      final catalog = TransportCatalog.initial;
      final encoded = catalog.encode();
      expect(catalog.encode(), encoded);
      final decoded = TransportCatalog.decode(encoded);
      expect(decoded.encode(), encoded);
      expect(decoded.toJson(), catalog.toJson());
    });

    test('keeps catalog membership separate from service availability', () {
      final serialized = TransportCatalog.initial.encode();
      expect(serialized, isNot(contains('availability')));
      expect(serialized, isNot(contains('routeEvidence')));
      expect(serialized, isNot(contains('durationMinutes')));
      expect(TransportCatalog.initial.modeById('ferry'), isNotNull);
    });

    test('rejects invalid JSON field types and version values', () {
      expect(
        () => TransportCatalog.fromJson({
          ...TransportCatalog.initial.toJson(),
          'schemaVersion': '1',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TransportCatalog.fromJson({
          ...TransportCatalog.initial.toJson(),
          'catalogVersion': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

TransportCatalog _catalog({int schemaVersion = 1, int catalogVersion = 1}) =>
    TransportCatalog(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      categories: TransportCatalog.initial.categories,
      modes: TransportCatalog.initial.modes,
    );

TransportCatalog _catalogWithCategories(List<TransportCategory> categories) =>
    TransportCatalog(
      schemaVersion: 1,
      catalogVersion: 1,
      categories: categories,
      modes: const [],
    );

TransportMode _copyMode(
  TransportMode mode, {
  String? categoryId,
  List<String>? aliases,
  bool? isActive,
  bool? requiresDirectedEndpoints,
}) => TransportMode(
  id: mode.id,
  categoryId: categoryId ?? mode.categoryId,
  labelKey: mode.labelKey,
  isActive: isActive ?? mode.isActive,
  legacyAliases: aliases ?? mode.legacyAliases,
  requiresDirectedEndpoints:
      requiresDirectedEndpoints ?? mode.requiresDirectedEndpoints,
  workflowCapabilities: mode.workflowCapabilities,
);
