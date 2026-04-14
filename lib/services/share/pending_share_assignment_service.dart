import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/route/port_call_item.dart';
import '../../models/share/share_intake_payload.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/hotel_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../store/cruise_store.dart';
import '../documents/cruise_document_section_service.dart';
import '../documents/excursion_document_section_service.dart';
import '../documents/port_call_document_section_service.dart';
import '../documents/travel_document_section_service.dart';
import 'share_intake_service.dart';

enum PendingShareAssignmentTargetType {
  cruise,
  excursion,
  travelItem,
  portCall,
}

enum PendingShareAssignmentOutcome {
  importedAndLinked,
  existingLinked,
  alreadyLinked,
}

class PendingShareAssignmentTarget {
  const PendingShareAssignmentTarget({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
  });

  final PendingShareAssignmentTargetType type;
  final String id;
  final String title;
  final String? subtitle;
}

class PendingShareAssignmentCruiseGroup {
  const PendingShareAssignmentCruiseGroup({
    required this.cruiseId,
    required this.cruiseTitle,
    required this.cruiseTarget,
    required this.excursions,
    required this.travelItems,
    required this.portCalls,
  });

  final String cruiseId;
  final String cruiseTitle;
  final PendingShareAssignmentTarget cruiseTarget;
  final List<PendingShareAssignmentTarget> excursions;
  final List<PendingShareAssignmentTarget> travelItems;
  final List<PendingShareAssignmentTarget> portCalls;
}

class PendingShareAssignmentSelectionData {
  const PendingShareAssignmentSelectionData({
    required this.item,
    required this.cruiseGroups,
  });

  final ShareIntakeItem? item;
  final List<PendingShareAssignmentCruiseGroup> cruiseGroups;

  bool get hasTargets => cruiseGroups.isNotEmpty;
}

class PendingShareAssignmentService {
  PendingShareAssignmentService({
    ShareIntakeService? shareIntakeService,
    CruiseStore? cruiseStore,
    CruiseDocumentSectionService? cruiseDocumentSectionService,
    ExcursionDocumentSectionService? excursionDocumentSectionService,
    TravelDocumentSectionService? travelDocumentSectionService,
    PortCallDocumentSectionService? portCallDocumentSectionService,
  })  : _shareIntakeService = shareIntakeService ?? ShareIntakeService(),
        _cruiseStore = cruiseStore ?? CruiseStore(),
        _cruiseDocumentSectionService =
            cruiseDocumentSectionService ?? CruiseDocumentSectionService(),
        _excursionDocumentSectionService =
            excursionDocumentSectionService ?? ExcursionDocumentSectionService(),
        _travelDocumentSectionService =
            travelDocumentSectionService ?? TravelDocumentSectionService(),
        _portCallDocumentSectionService =
            portCallDocumentSectionService ?? PortCallDocumentSectionService();

  final ShareIntakeService _shareIntakeService;
  final CruiseStore _cruiseStore;
  final CruiseDocumentSectionService _cruiseDocumentSectionService;
  final ExcursionDocumentSectionService _excursionDocumentSectionService;
  final TravelDocumentSectionService _travelDocumentSectionService;
  final PortCallDocumentSectionService _portCallDocumentSectionService;

  bool canAssignItem(ShareIntakeItem item) => item.isFileBased;

  Future<PendingShareAssignmentSelectionData> loadSelectionData({
    required String batchId,
    required int itemIndex,
    required AppLocalizations loc,
  }) async {
    if (!_cruiseStore.isLoaded) {
      await _cruiseStore.load();
    }

    final item = _shareIntakeService.getPendingItem(
      batchId: batchId,
      itemIndex: itemIndex,
    );
    final cruiseGroups = _cruiseStore.activeCruises
        .map((cruise) => _buildCruiseGroup(cruise, loc))
        .toList(growable: false);

    return PendingShareAssignmentSelectionData(
      item: item,
      cruiseGroups: cruiseGroups,
    );
  }

  Future<PendingShareAssignmentOutcome> assignPendingItem({
    required String batchId,
    required int itemIndex,
    required PendingShareAssignmentTarget target,
    String? title,
  }) async {
    final item = _shareIntakeService.getPendingItem(
      batchId: batchId,
      itemIndex: itemIndex,
    );
    if (item == null) {
      throw StateError('Pending share item not found.');
    }
    if (!canAssignItem(item)) {
      throw UnsupportedError('Pending share item is not assignable.');
    }

    final normalizedPath = item.value.trim();
    if (normalizedPath.isEmpty) {
      throw StateError('Pending share item has no source path.');
    }

    final outcome = switch (target.type) {
      PendingShareAssignmentTargetType.cruise => _mapCruiseOutcome(
          await _cruiseDocumentSectionService.importDocument(
            cruiseId: target.id,
            sourcePath: normalizedPath,
            title: title,
          ),
        ),
      PendingShareAssignmentTargetType.excursion => _mapExcursionOutcome(
          await _excursionDocumentSectionService.importDocument(
            excursionId: target.id,
            sourcePath: normalizedPath,
            title: title,
          ),
        ),
      PendingShareAssignmentTargetType.travelItem => _mapTravelOutcome(
          await _travelDocumentSectionService.importDocument(
            travelItemId: target.id,
            sourcePath: normalizedPath,
            title: title,
          ),
        ),
      PendingShareAssignmentTargetType.portCall => _mapPortCallOutcome(
          await _portCallDocumentSectionService.importDocument(
            portCallId: target.id,
            sourcePath: normalizedPath,
            title: title,
          ),
        ),
    };

    await _shareIntakeService.removePendingItem(
      batchId: batchId,
      itemIndex: itemIndex,
    );
    return outcome;
  }

  PendingShareAssignmentCruiseGroup _buildCruiseGroup(
    Cruise cruise,
    AppLocalizations loc,
  ) {
    final cruiseTitle = cruise.title.trim().isEmpty
        ? loc.cruise
        : cruise.title.trim();

    return PendingShareAssignmentCruiseGroup(
      cruiseId: cruise.id,
      cruiseTitle: cruiseTitle,
      cruiseTarget: PendingShareAssignmentTarget(
        type: PendingShareAssignmentTargetType.cruise,
        id: cruise.id,
        title: cruiseTitle,
      ),
      excursions: cruise.excursions
          .map((excursion) => _buildExcursionTarget(excursion, loc))
          .toList(growable: false),
      travelItems: cruise.travel
          .map((travelItem) => _buildTravelTarget(travelItem, loc))
          .toList(growable: false),
      portCalls: cruise.route
          .whereType<PortCallItem>()
          .map((portCall) => _buildPortCallTarget(portCall, loc))
          .toList(growable: false),
    );
  }

  PendingShareAssignmentTarget _buildExcursionTarget(
    Excursion excursion,
    AppLocalizations loc,
  ) {
    final title = excursion.title.trim().isEmpty
        ? loc.excursion
        : excursion.title.trim();

    return PendingShareAssignmentTarget(
      type: PendingShareAssignmentTargetType.excursion,
      id: excursion.id,
      title: title,
      subtitle: excursion.port?.trim().isNotEmpty == true
          ? excursion.port!.trim()
          : null,
    );
  }

  PendingShareAssignmentTarget _buildTravelTarget(
    TravelItem travelItem,
    AppLocalizations loc,
  ) {
    return PendingShareAssignmentTarget(
      type: PendingShareAssignmentTargetType.travelItem,
      id: travelItem.id,
      title: _travelTitle(travelItem, loc),
      subtitle: _travelSubtitle(travelItem),
    );
  }

  PendingShareAssignmentTarget _buildPortCallTarget(
    PortCallItem portCall,
    AppLocalizations loc,
  ) {
    final portName = portCall.portName.trim();
    return PendingShareAssignmentTarget(
      type: PendingShareAssignmentTargetType.portCall,
      id: portCall.id,
      title: portName.isEmpty ? loc.harbour : portName,
    );
  }

  PendingShareAssignmentOutcome _mapCruiseOutcome(
    CruiseDocumentImportResult result,
  ) {
    switch (result.outcome) {
      case CruiseDocumentImportOutcome.importedAndLinked:
        return PendingShareAssignmentOutcome.importedAndLinked;
      case CruiseDocumentImportOutcome.existingLinked:
        return PendingShareAssignmentOutcome.existingLinked;
      case CruiseDocumentImportOutcome.alreadyLinked:
        return PendingShareAssignmentOutcome.alreadyLinked;
    }
  }

  PendingShareAssignmentOutcome _mapExcursionOutcome(
    ExcursionDocumentImportResult result,
  ) {
    switch (result.outcome) {
      case ExcursionDocumentImportOutcome.importedAndLinked:
        return PendingShareAssignmentOutcome.importedAndLinked;
      case ExcursionDocumentImportOutcome.existingLinked:
        return PendingShareAssignmentOutcome.existingLinked;
      case ExcursionDocumentImportOutcome.alreadyLinked:
        return PendingShareAssignmentOutcome.alreadyLinked;
    }
  }

  PendingShareAssignmentOutcome _mapTravelOutcome(
    TravelDocumentImportResult result,
  ) {
    switch (result.outcome) {
      case TravelDocumentImportOutcome.importedAndLinked:
        return PendingShareAssignmentOutcome.importedAndLinked;
      case TravelDocumentImportOutcome.existingLinked:
        return PendingShareAssignmentOutcome.existingLinked;
      case TravelDocumentImportOutcome.alreadyLinked:
        return PendingShareAssignmentOutcome.alreadyLinked;
    }
  }

  PendingShareAssignmentOutcome _mapPortCallOutcome(
    PortCallDocumentImportResult result,
  ) {
    switch (result.outcome) {
      case PortCallDocumentImportOutcome.importedAndLinked:
        return PendingShareAssignmentOutcome.importedAndLinked;
      case PortCallDocumentImportOutcome.existingLinked:
        return PendingShareAssignmentOutcome.existingLinked;
      case PortCallDocumentImportOutcome.alreadyLinked:
        return PendingShareAssignmentOutcome.alreadyLinked;
    }
  }

  String _travelTitle(TravelItem item, AppLocalizations loc) {
    switch (item.kind) {
      case TravelKind.flight:
        final flight = item as FlightItem;
        final carrier = (flight.carrier ?? '').trim();
        final flightNo = (flight.flightNo ?? '').trim();
        final combined = [carrier, flightNo]
            .where((value) => value.isNotEmpty)
            .join(' ');
        return combined.isEmpty ? loc.flight : combined;
      case TravelKind.train:
        return loc.train;
      case TravelKind.transfer:
        final transfer = item as TransferItem;
        final mode = transfer.mode?.name.trim() ?? '';
        return mode.isEmpty ? loc.transfer : mode;
      case TravelKind.rentalCar:
        final rentalCar = item as RentalCarItem;
        final company = (rentalCar.company ?? '').trim();
        return company.isEmpty ? loc.rentalCar : company;
      case TravelKind.hotel:
        final hotel = item as HotelItem;
        final name = hotel.name.trim();
        return name.isEmpty ? loc.hotel : name;
      case TravelKind.cruiseCheckIn:
        return loc.cruiseCheckIn;
      case TravelKind.cruiseCheckOut:
        return loc.cruiseCheckOut;
    }
  }

  String? _travelSubtitle(TravelItem item) {
    final from = item.from?.trim() ?? '';
    final to = item.to?.trim() ?? '';
    if (from.isEmpty && to.isEmpty) {
      return null;
    }
    if (from.isEmpty) {
      return to;
    }
    if (to.isEmpty) {
      return from;
    }
    return '$from -> $to';
  }
}
