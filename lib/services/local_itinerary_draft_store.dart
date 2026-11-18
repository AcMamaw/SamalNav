import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/destination_record.dart';
import '../models/itinerary_draft.dart';
import '../models/price_info.dart';

/// Stores editable, unoptimized itinerary drafts on this device only.
///
/// This uses its own Hive box so local edits cannot be confused with the
/// synchronized-record snapshots stored by the offline cache service.
class LocalItineraryDraftStore {
  static const String boxName = 'samal_nav_local_itinerary_drafts_v1';
  static const int formatVersion = 1;
  static const String _keyPrefix = 'draft:';

  final Box<String> _box;

  LocalItineraryDraftStore({required Box<String> box}) : _box = box;

  static Future<LocalItineraryDraftStore> open() async =>
      LocalItineraryDraftStore(box: await Hive.openBox<String>(boxName));

  Future<void> saveDraft(ItineraryDraft draft, {DateTime? savedAt}) async {
    if (draft.method != PlanningMethod.manualSelection ||
        draft.stage != DraftStage.draftReview ||
        draft.optimizationResult != null) {
      throw StateError(
        'Only unoptimized manual-selection drafts in review can be saved locally.',
      );
    }
    if (draft.id.isEmpty) {
      throw ArgumentError.value(draft.id, 'draft.id', 'Must not be empty.');
    }

    final record = <String, Object?>{
      'formatVersion': formatVersion,
      'storageState': 'localDraft',
      'savedAt': (savedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'draft': _draftToJson(draft),
    };
    await _box.put('$_keyPrefix${draft.id}', jsonEncode(record));
  }

  List<ItineraryDraft> readDrafts() {
    final drafts = <ItineraryDraft>[];
    for (final key in _box.keys.whereType<String>().where(
      (key) => key.startsWith(_keyPrefix),
    )) {
      final record = _readRecord(_box.get(key)!);
      drafts.add(_draftFromJson(_asMap(record['draft'], 'draft')));
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(drafts);
  }

  ItineraryDraft? readDraft(String draftId) {
    final raw = _box.get('$_keyPrefix$draftId');
    if (raw == null) return null;
    final record = _readRecord(raw);
    return _draftFromJson(_asMap(record['draft'], 'draft'));
  }

  Map<String, dynamic> _readRecord(String raw) {
    final decoded = jsonDecode(raw);
    final record = _asMap(decoded, 'local draft record');
    if (record['formatVersion'] != formatVersion) {
      throw FormatException(
        'Unsupported local itinerary draft format version: '
        '${record['formatVersion']}. The stored record was left unchanged.',
      );
    }
    if (record['storageState'] != 'localDraft') {
      throw const FormatException('Record is not a locally saved draft.');
    }
    return record;
  }

  static Map<String, Object?> _draftToJson(ItineraryDraft draft) => {
    'id': draft.id,
    'method': draft.method.name,
    'stage': draft.stage.name,
    'createdAt': draft.createdAt.toIso8601String(),
    'updatedAt': draft.updatedAt.toIso8601String(),
    'trip': _tripToJson(draft.trip),
    'stops': draft.stops.map(_stopToJson).toList(),
    'selectedCircuits': draft.selectedCircuits
        .map(
          (circuit) => {
            'id': circuit.id,
            'name': circuit.name,
            'officialSource': circuit.officialSource,
          },
        )
        .toList(),
    'carsRunReference': draft.carsRunReference?.id,
  };

  static ItineraryDraft _draftFromJson(Map<String, dynamic> json) {
    final method = _enumByName(PlanningMethod.values, json['method'], 'method');
    final stage = _enumByName(DraftStage.values, json['stage'], 'stage');
    final rawCircuits = json['selectedCircuits'];
    final circuits = rawCircuits == null
        ? const <CircuitReference>[]
        : _asList(rawCircuits, 'selectedCircuits').map((item) {
            final circuit = _asMap(item, 'selected circuit');
            return CircuitReference(
              id: _requiredString(circuit['id'], 'circuit.id'),
              name: _requiredString(circuit['name'], 'circuit.name'),
              officialSource: circuit['officialSource'] as String?,
            );
          }).toList();

    return ItineraryDraft(
      id: _requiredString(json['id'], 'draft.id'),
      method: method,
      stage: stage,
      createdAt: _dateTime(json['createdAt'], 'draft.createdAt'),
      updatedAt: _dateTime(json['updatedAt'], 'draft.updatedAt'),
      trip: _tripFromJson(_asMap(json['trip'], 'trip')),
      stops: _asList(
        json['stops'],
        'stops',
      ).map((item) => _stopFromJson(_asMap(item, 'stop'))).toList(),
      selectedCircuits: circuits,
      carsRunReference: json['carsRunReference'] == null
          ? null
          : CarsRunReference(
              _requiredString(json['carsRunReference'], 'carsRunReference'),
            ),
    );
  }

  static Map<String, Object?> _tripToJson(TripConfiguration trip) => {
    'startDate': trip.startDate?.toIso8601String(),
    'durationDays': trip.durationDays,
    'availableHoursPerDay': trip.availableHoursPerDay,
    'budgetMinimum': trip.budgetMinimum,
    'budgetMaximum': trip.budgetMaximum,
    'budgetBasis': trip.budgetBasis?.name,
    'currency': trip.currency,
    'totalGroupSize': trip.totalGroupSize,
    'childrenCount': trip.childrenCount,
    'eldersCount': trip.eldersCount,
    'origin': trip.origin == null
        ? null
        : {
            'latitude': trip.origin!.latitude,
            'longitude': trip.origin!.longitude,
            'label': trip.origin!.label,
          },
    'travelMode': trip.travelMode?.name,
    'requiredTransfers': trip.requiredTransfers
        .map(
          (transfer) => {
            'fromDestinationId': transfer.fromDestinationId,
            'toDestinationId': transfer.toDestinationId,
            'kind': transfer.kind.name,
          },
        )
        .toList(),
  };

  static TripConfiguration _tripFromJson(Map<String, dynamic> json) {
    final originJson = json['origin'];
    final origin = originJson == null
        ? null
        : _asMap(originJson, 'trip.origin');
    final transfersJson = json['requiredTransfers'];
    final transfers = transfersJson == null
        ? const <RequiredTransfer>[]
        : _asList(transfersJson, 'requiredTransfers').map((item) {
            final transfer = _asMap(item, 'required transfer');
            return RequiredTransfer(
              fromDestinationId: _requiredString(
                transfer['fromDestinationId'],
                'transfer.fromDestinationId',
              ),
              toDestinationId: _requiredString(
                transfer['toDestinationId'],
                'transfer.toDestinationId',
              ),
              kind: _enumByName(
                RequiredTransferKind.values,
                transfer['kind'],
                'transfer.kind',
              ),
            );
          }).toList();

    return TripConfiguration(
      startDate: json['startDate'] == null
          ? null
          : _dateTime(json['startDate'], 'trip.startDate'),
      durationDays: _requiredInt(json['durationDays'], 'trip.durationDays'),
      availableHoursPerDay: _requiredInt(
        json['availableHoursPerDay'],
        'trip.availableHoursPerDay',
      ),
      budgetMinimum: _nullableDouble(json['budgetMinimum'], 'budgetMinimum'),
      budgetMaximum: _nullableDouble(json['budgetMaximum'], 'budgetMaximum'),
      budgetBasis: json['budgetBasis'] == null
          ? null
          : _enumByName(BudgetBasis.values, json['budgetBasis'], 'budgetBasis'),
      currency: json['currency'] as String?,
      totalGroupSize: _nullableInt(json['totalGroupSize'], 'totalGroupSize'),
      childrenCount: _nullableInt(json['childrenCount'], 'childrenCount'),
      eldersCount: _nullableInt(json['eldersCount'], 'eldersCount'),
      origin: origin == null
          ? null
          : TripOrigin(
              latitude: _requiredDouble(origin['latitude'], 'origin.latitude'),
              longitude: _requiredDouble(
                origin['longitude'],
                'origin.longitude',
              ),
              label: origin['label'] as String?,
            ),
      travelMode: json['travelMode'] == null
          ? null
          : _enumByName(
              PreferredTravelMode.values,
              json['travelMode'],
              'travelMode',
            ),
      requiredTransfers: transfers,
    );
  }

  static Map<String, Object?> _stopToJson(DraftStop stop) => {
    'destinationId': stop.destinationId,
    'selectionOrder': stop.selectionOrder,
    'assignedDay': stop.assignedDay,
    'selectedActivityIds': stop.selectedActivityIds,
    'isIncluded': stop.isIncluded,
    'provenance': stop.provenance
        .map(
          (source) => {
            'kind': source.kind.name,
            'sourceId': source.sourceId,
            'sourceName': source.sourceName,
          },
        )
        .toList(),
    'destination': _destinationToJson(stop.destination),
  };

  static DraftStop _stopFromJson(Map<String, dynamic> json) {
    final provenance = _asList(json['provenance'], 'stop.provenance').map((
      item,
    ) {
      final source = _asMap(item, 'stop provenance');
      return StopProvenance(
        kind: _enumByName(
          StopProvenanceKind.values,
          source['kind'],
          'provenance.kind',
        ),
        sourceId: source['sourceId'] as String?,
        sourceName: source['sourceName'] as String?,
      );
    }).toSet();
    final activityIds = json['selectedActivityIds'] == null
        ? const <String>[]
        : _asList(json['selectedActivityIds'], 'selectedActivityIds')
              .map((value) => _requiredString(value, 'selectedActivityId'))
              .toList();

    return DraftStop(
      destinationId: _requiredString(json['destinationId'], 'destinationId'),
      destination: _destinationFromJson(
        _asMap(json['destination'], 'stop.destination'),
      ),
      selectionOrder: _requiredInt(json['selectionOrder'], 'selectionOrder'),
      assignedDay: _nullableInt(json['assignedDay'], 'assignedDay'),
      provenance: provenance,
      selectedActivityIds: activityIds,
      isIncluded: json['isIncluded'] as bool? ?? true,
    );
  }

  static Map<String, Object?> _destinationToJson(
    DestinationDisplaySnapshot destination,
  ) => {
    'id': destination.id,
    'name': destination.name,
    'location': destination.location,
    'category': destination.category,
    'categoryId': destination.categoryId,
    'latitude': destination.latitude,
    'longitude': destination.longitude,
    'visitDurationMinutes': destination.visitDurationMinutes,
    'entrancePriceRaw': _jsonValue(destination.entrancePrice.rawValue),
    'recordSource': destination.recordSource.name,
    'isActive': destination.isActive,
    'isVerified': destination.isVerified,
    'hasUsableCoordinates': destination.hasUsableCoordinates,
    'hasUsableVisitDuration': destination.hasUsableVisitDuration,
  };

  static DestinationDisplaySnapshot _destinationFromJson(
    Map<String, dynamic> json,
  ) => DestinationDisplaySnapshot(
    id: _requiredString(json['id'], 'destination.id'),
    name: _requiredString(json['name'], 'destination.name'),
    location: _requiredString(json['location'], 'destination.location'),
    category: _requiredString(json['category'], 'destination.category'),
    categoryId: json['categoryId'] as String?,
    latitude: _requiredDouble(json['latitude'], 'destination.latitude'),
    longitude: _requiredDouble(json['longitude'], 'destination.longitude'),
    visitDurationMinutes: _requiredInt(
      json['visitDurationMinutes'],
      'destination.visitDurationMinutes',
    ),
    entrancePrice: PriceInfo.fromRaw(json['entrancePriceRaw']),
    recordSource: _enumByName(
      DestinationRecordSource.values,
      json['recordSource'],
      'destination.recordSource',
    ),
    isActive: json['isActive'] as bool? ?? false,
    isVerified: json['isVerified'] as bool? ?? false,
    hasUsableCoordinates: json['hasUsableCoordinates'] as bool? ?? false,
    hasUsableVisitDuration: json['hasUsableVisitDuration'] as bool? ?? false,
  );

  static Object? _jsonValue(Object? value) {
    if (value == null || value is String || value is bool) return value;
    if (value is num && value.isFinite) return value;
    throw FormatException(
      'Unsupported local draft value type: ${value.runtimeType}.',
    );
  }

  static Map<String, dynamic> _asMap(Object? value, String label) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('$label must be an object.');
  }

  static List<Object?> _asList(Object? value, String label) {
    if (value is List) return List<Object?>.from(value);
    throw FormatException('$label must be a list.');
  }

  static String _requiredString(Object? value, String label) {
    if (value is String) return value;
    throw FormatException('$label must be a string.');
  }

  static int _requiredInt(Object? value, String label) {
    if (value is int) return value;
    throw FormatException('$label must be an integer.');
  }

  static int? _nullableInt(Object? value, String label) =>
      value == null ? null : _requiredInt(value, label);

  static double _requiredDouble(Object? value, String label) {
    if (value is num && value.isFinite) return value.toDouble();
    throw FormatException('$label must be a finite number.');
  }

  static double? _nullableDouble(Object? value, String label) =>
      value == null ? null : _requiredDouble(value, label);

  static DateTime _dateTime(Object? value, String label) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('$label must be an ISO-8601 datetime.');
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? value,
    String label,
  ) {
    if (value is String) {
      for (final item in values) {
        if (item.name == value) return item;
      }
    }
    throw FormatException('$label contains an unknown value: $value.');
  }
}
