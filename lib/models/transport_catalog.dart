import 'dart:convert';

/// Local, versioned transportation vocabulary.
///
/// Catalog membership describes an application concept only. It does not
/// establish that a transportation service or route is available.
class TransportCatalog {
  static const int initialSchemaVersion = 1;
  static const int initialCatalogVersion = 1;

  final int schemaVersion;
  final int catalogVersion;
  final List<TransportCategory> categories;
  final List<TransportMode> modes;

  factory TransportCatalog({
    required int schemaVersion,
    required int catalogVersion,
    required List<TransportCategory> categories,
    required List<TransportMode> modes,
  }) {
    final catalog = TransportCatalog._(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      categories: List.unmodifiable(categories),
      modes: List.unmodifiable(modes),
    );
    catalog.validate();
    return catalog;
  }

  TransportCatalog._({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.categories,
    required this.modes,
  });

  static final TransportCatalog initial = TransportCatalog(
    schemaVersion: initialSchemaVersion,
    catalogVersion: initialCatalogVersion,
    categories: const [
      TransportCategory(id: 'land', labelKey: 'transport.category.land'),
      TransportCategory(
        id: 'land_non_motorized',
        labelKey: 'transport.category.land_non_motorized',
        parentId: 'land',
      ),
      TransportCategory(
        id: 'land_motorized',
        labelKey: 'transport.category.land_motorized',
        parentId: 'land',
      ),
      TransportCategory(
        id: 'public_transport',
        labelKey: 'transport.category.public_transport',
      ),
      TransportCategory(
        id: 'public_transport_local',
        labelKey: 'transport.category.public_transport_local',
        parentId: 'public_transport',
      ),
      TransportCategory(id: 'water', labelKey: 'transport.category.water'),
      TransportCategory(
        id: 'water_transfer',
        labelKey: 'transport.category.water_transfer',
        parentId: 'water',
      ),
    ],
    modes: [
      _initialMode('walking', 'land_non_motorized'),
      _initialMode('bicycle', 'land_non_motorized'),
      _initialMode('motorcycle', 'land_motorized'),
      _initialMode('car', 'land_motorized'),
      _initialMode(
        'public_transportation',
        'public_transport_local',
        aliases: const ['public transportation', 'publicTransportation'],
      ),
      _initialMode('jeepney', 'public_transport_local'),
      _initialMode('tricycle', 'public_transport_local'),
      _initialMode('multicab', 'public_transport_local'),
      _initialMode('van', 'public_transport_local'),
      _initialMode('bus', 'public_transport_local'),
      _initialMode('ferry', 'water_transfer', requiresDirectedEndpoints: true),
      _initialMode('boat', 'water_transfer', requiresDirectedEndpoints: true),
    ],
  );

  TransportMode? modeById(String id) {
    for (final mode in modes) {
      if (mode.id == id) return mode;
    }
    return null;
  }

  TransportModeReference decodeMode(
    String rawIdentifier, {
    String? labelSnapshot,
  }) {
    for (final mode in modes) {
      if (mode.id == rawIdentifier ||
          mode.legacyAliases.contains(rawIdentifier)) {
        return TransportModeReference._(
          modeId: mode.id,
          labelSnapshot: labelSnapshot,
          definition: mode,
        );
      }
    }
    return TransportModeReference._(
      modeId: rawIdentifier,
      labelSnapshot: labelSnapshot,
      definition: null,
    );
  }

  /// Returns null when the value is unknown or the known entry is inactive.
  TransportMode? selectableMode(String identifier) {
    final reference = decodeMode(identifier);
    final mode = reference.definition;
    return mode != null && mode.isActive ? mode : null;
  }

  void validate() {
    if (schemaVersion <= 0) {
      throw const FormatException('schemaVersion must be a positive integer.');
    }
    if (catalogVersion <= 0) {
      throw const FormatException('catalogVersion must be a positive integer.');
    }

    final categoryById = <String, TransportCategory>{};
    for (final category in categories) {
      _validateIdentifier(category.id, 'category id');
      _validateNonEmpty(category.labelKey, 'category labelKey');
      if (categoryById.containsKey(category.id)) {
        throw FormatException('Duplicate category id: ${category.id}');
      }
      categoryById[category.id] = category;
    }

    final depthById = <String, int>{};
    int categoryDepth(String id, Set<String> visiting) {
      final knownDepth = depthById[id];
      if (knownDepth != null) return knownDepth;
      if (!visiting.add(id)) {
        throw FormatException('Category cycle includes: $id');
      }
      final category = categoryById[id]!;
      final parentId = category.parentId;
      final depth = parentId == null
          ? 0
          : categoryDepth(parentId, visiting) + 1;
      visiting.remove(id);
      if (depth > 2) {
        throw FormatException('Category depth exceeds two edges at: $id');
      }
      depthById[id] = depth;
      return depth;
    }

    for (final category in categories) {
      final parentId = category.parentId;
      if (parentId != null && !categoryById.containsKey(parentId)) {
        throw FormatException(
          'Category ${category.id} references missing parent: $parentId',
        );
      }
      categoryDepth(category.id, <String>{});
    }

    final modeIds = <String>{};
    final aliases = <String, String>{};
    for (final mode in modes) {
      _validateIdentifier(mode.id, 'mode id');
      _validateNonEmpty(mode.labelKey, 'mode labelKey');
      if (!modeIds.add(mode.id)) {
        throw FormatException('Duplicate mode id: ${mode.id}');
      }
      if (!categoryById.containsKey(mode.categoryId)) {
        throw FormatException(
          'Mode ${mode.id} references missing category: ${mode.categoryId}',
        );
      }
      for (final alias in mode.legacyAliases) {
        _validateNonEmpty(alias, 'legacy alias');
        if (modeIds.contains(alias)) {
          throw FormatException(
            'Legacy alias collides with a canonical mode id: $alias',
          );
        }
        final previousOwner = aliases[alias];
        if (previousOwner != null) {
          throw FormatException(
            'Legacy alias $alias belongs to both $previousOwner and ${mode.id}.',
          );
        }
        aliases[alias] = mode.id;
      }
      if (mode.categoryId == 'water_transfer' &&
          !mode.requiresDirectedEndpoints) {
        throw FormatException(
          'Water transfer mode ${mode.id} must require directed endpoints.',
        );
      }
      if (mode.categoryId != 'water_transfer' &&
          mode.requiresDirectedEndpoints) {
        throw FormatException(
          'Non-water mode ${mode.id} cannot require water endpoints.',
        );
      }
    }

    for (final alias in aliases.keys) {
      if (modeIds.contains(alias)) {
        throw FormatException(
          'Legacy alias collides with a canonical mode id: $alias',
        );
      }
    }
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'catalogVersion': catalogVersion,
    'categories': [for (final category in categories) category.toJson()],
    'modes': [for (final mode in modes) mode.toJson()],
  };

  String encode() => _encodeDeterministically(toJson());

  factory TransportCatalog.fromJson(Map<String, Object?> json) {
    final schemaVersion = _readInt(json, 'schemaVersion');
    final catalogVersion = _readInt(json, 'catalogVersion');
    final rawCategories = _readList(json, 'categories');
    final rawModes = _readList(json, 'modes');
    return TransportCatalog(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      categories: [
        for (final value in rawCategories)
          TransportCategory.fromJson(_readMap(value, 'category')),
      ],
      modes: [
        for (final value in rawModes)
          TransportMode.fromJson(_readMap(value, 'mode')),
      ],
    );
  }

  factory TransportCatalog.decode(String encoded) {
    final value = jsonDecode(encoded);
    return TransportCatalog.fromJson(_readMap(value, 'catalog'));
  }
}

TransportMode _initialMode(
  String id,
  String categoryId, {
  List<String> aliases = const [],
  bool requiresDirectedEndpoints = false,
}) => TransportMode(
  id: id,
  categoryId: categoryId,
  labelKey: 'transport.mode.$id',
  isActive: true,
  legacyAliases: aliases,
  requiresDirectedEndpoints: requiresDirectedEndpoints,
  workflowCapabilities: const WorkflowCapabilities(
    profilePreference: true,
    manualLegSelection: true,
    circuitPlanning: false,
    mogaRouteEvaluation: false,
    fixedCommitmentCapture: true,
  ),
);

class TransportCategory {
  final String id;
  final String labelKey;
  final String? parentId;

  const TransportCategory({
    required this.id,
    required this.labelKey,
    this.parentId,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'labelKey': labelKey,
    'parentId': parentId,
  };

  factory TransportCategory.fromJson(Map<String, Object?> json) =>
      TransportCategory(
        id: _readString(json, 'id'),
        labelKey: _readString(json, 'labelKey'),
        parentId: _readNullableString(json, 'parentId'),
      );
}

class TransportMode {
  final String id;
  final String categoryId;
  final String labelKey;
  final bool isActive;
  final List<String> legacyAliases;
  final bool requiresDirectedEndpoints;
  final WorkflowCapabilities workflowCapabilities;

  TransportMode({
    required this.id,
    required this.categoryId,
    required this.labelKey,
    required this.isActive,
    required List<String> legacyAliases,
    required this.requiresDirectedEndpoints,
    required this.workflowCapabilities,
  }) : legacyAliases = List.unmodifiable(legacyAliases);

  Map<String, Object?> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'labelKey': labelKey,
    'isActive': isActive,
    'legacyAliases': List<String>.of(legacyAliases),
    'requiresDirectedEndpoints': requiresDirectedEndpoints,
    'workflowCapabilities': workflowCapabilities.toJson(),
  };

  factory TransportMode.fromJson(Map<String, Object?> json) => TransportMode(
    id: _readString(json, 'id'),
    categoryId: _readString(json, 'categoryId'),
    labelKey: _readString(json, 'labelKey'),
    isActive: _readBool(json, 'isActive'),
    legacyAliases: _readStringList(json, 'legacyAliases'),
    requiresDirectedEndpoints: _readBool(json, 'requiresDirectedEndpoints'),
    workflowCapabilities: WorkflowCapabilities.fromJson(
      _readMap(json['workflowCapabilities'], 'workflowCapabilities'),
    ),
  );
}

class WorkflowCapabilities {
  final bool profilePreference;
  final bool manualLegSelection;
  final bool circuitPlanning;
  final bool mogaRouteEvaluation;
  final bool fixedCommitmentCapture;

  const WorkflowCapabilities({
    required this.profilePreference,
    required this.manualLegSelection,
    required this.circuitPlanning,
    required this.mogaRouteEvaluation,
    required this.fixedCommitmentCapture,
  });

  Map<String, Object?> toJson() => {
    'profilePreference': profilePreference,
    'manualLegSelection': manualLegSelection,
    'circuitPlanning': circuitPlanning,
    'mogaRouteEvaluation': mogaRouteEvaluation,
    'fixedCommitmentCapture': fixedCommitmentCapture,
  };

  factory WorkflowCapabilities.fromJson(Map<String, Object?> json) =>
      WorkflowCapabilities(
        profilePreference: _readBool(json, 'profilePreference'),
        manualLegSelection: _readBool(json, 'manualLegSelection'),
        circuitPlanning: _readBool(json, 'circuitPlanning'),
        mogaRouteEvaluation: _readBool(json, 'mogaRouteEvaluation'),
        fixedCommitmentCapture: _readBool(json, 'fixedCommitmentCapture'),
      );
}

/// A decoded mode reference, including unknown or inactive historical values.
class TransportModeReference {
  final String modeId;
  final String? labelSnapshot;
  final TransportMode? definition;

  const TransportModeReference._({
    required this.modeId,
    required this.labelSnapshot,
    required this.definition,
  });

  bool get isSupported => definition != null;
  bool get isActive => definition?.isActive ?? false;
  bool get canSelectForNewUse => isSupported && isActive;

  Map<String, Object?> toJson() => {
    'modeId': modeId,
    if (labelSnapshot != null) 'labelSnapshot': labelSnapshot,
  };

  factory TransportModeReference.fromJson(
    Map<String, Object?> json,
    TransportCatalog catalog,
  ) => catalog.decodeMode(
    _readString(json, 'modeId'),
    labelSnapshot: _readNullableString(json, 'labelSnapshot'),
  );
}

void _validateIdentifier(String value, String field) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    throw FormatException(
      '$field must use lowercase snake_case identifier syntax: $value',
    );
  }
}

void _validateNonEmpty(String value, String field) {
  if (value.trim().isEmpty) {
    throw FormatException('$field must not be empty.');
  }
}

String _encodeDeterministically(Object? value) {
  Object? normalize(Object? current) {
    if (current is Map) {
      final keys = current.keys.cast<String>().toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: normalize(current[key]),
      };
    }
    if (current is List) return current.map(normalize).toList();
    return current;
  }

  return jsonEncode(normalize(value));
}

Map<String, Object?> _readMap(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be a JSON object.');
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string object key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _readList(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! List) throw FormatException('$field must be a JSON array.');
  return value.cast<Object?>();
}

List<String> _readStringList(Map<String, Object?> json, String field) => [
  for (final value in _readList(json, field))
    if (value is String)
      value
    else
      throw FormatException('$field must contain strings.'),
];

String _readString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

String? _readNullableString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String)
    throw FormatException('$field must be a string or null.');
  return value;
}

int _readInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! int) throw FormatException('$field must be an integer.');
  return value;
}

bool _readBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}
