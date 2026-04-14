import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/travel/base_travel.dart';
import '../../models/travel/flight_item.dart';
import '../../models/travel/hotel_item.dart';
import '../../models/travel/rental_car_item.dart';
import '../../models/travel/transfer_item.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../widgets/documents/travel_documents_section.dart';
import 'travel_edit_screen.dart';

class TravelDetailScreen extends StatefulWidget {
  const TravelDetailScreen({
    super.key,
    required this.travelItemId,
  });

  final String travelItemId;

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  TravelItem? _item;
  String? _cruiseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    final item = store.getById<TravelItem>(widget.travelItemId);
    String? cruiseId;

    for (final cruise in store.activeCruises) {
      if (cruise.travel.any((travelItem) => travelItem.id == widget.travelItemId)) {
        cruiseId = cruise.id;
        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _item = item;
      _cruiseId = cruiseId;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final item = _item;
    if (item == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TravelEditScreen(travelItemId: item.id),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.travel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = _item;
    if (item == null || _cruiseId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.travel)),
        body: Center(child: Text(loc.noTravelItem)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForItem(context, item)),
        actions: [
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            tooltip: loc.editTravel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TravelInfoSection(item: item),
          const SizedBox(height: 16),
          TravelDocumentsSection(
            key: ValueKey('travel-documents-${item.id}-${item.documentIds.join('|')}'),
            travelItemId: item.id,
            isReadOnly: true,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit),
            label: Text(loc.editTravel),
          ),
        ],
      ),
    );
  }

  String _titleForItem(BuildContext context, TravelItem item) {
    final loc = AppLocalizations.of(context)!;
    switch (item.kind) {
      case TravelKind.flight:
        return loc.flight;
      case TravelKind.train:
        return loc.train;
      case TravelKind.transfer:
        return loc.transfer;
      case TravelKind.rentalCar:
        return loc.rentalCar;
      case TravelKind.hotel:
        return loc.hotel;
      case TravelKind.cruiseCheckIn:
        return loc.cruiseCheckIn;
      case TravelKind.cruiseCheckOut:
        return loc.cruiseCheckOut;
    }
  }
}

class _TravelInfoSection extends StatelessWidget {
  const _TravelInfoSection({required this.item});

  final TravelItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sectionTitle(context, item),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._buildRows(context),
          ],
        ),
      ),
    );
  }

  String _sectionTitle(BuildContext context, TravelItem item) {
    final loc = AppLocalizations.of(context)!;
    switch (item.kind) {
      case TravelKind.flight:
        final flight = item as FlightItem;
        if ((flight.flightNo ?? '').isNotEmpty) {
          return flight.flightNo!;
        }
        return loc.flight;
      case TravelKind.hotel:
        final hotel = item as HotelItem;
        return hotel.name.isNotEmpty ? hotel.name : loc.hotel;
      case TravelKind.train:
        return loc.train;
      case TravelKind.transfer:
        return loc.transfer;
      case TravelKind.rentalCar:
        return loc.rentalCar;
      case TravelKind.cruiseCheckIn:
        return loc.cruiseCheckIn;
      case TravelKind.cruiseCheckOut:
        return loc.cruiseCheckOut;
    }
  }

  List<Widget> _buildRows(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return <Widget>[
      if ((item.from ?? '').isNotEmpty)
        _InfoTile(
          icon: Icons.location_on_outlined,
          label: loc.from,
          value: item.from!,
        ),
      if ((item.to ?? '').isNotEmpty)
        _InfoTile(
          icon: Icons.flag_outlined,
          label: loc.to,
          value: item.to!,
        ),
      _InfoTile(
        icon: Icons.event_outlined,
        label: loc.start,
        value: fmtDate(context, item.start, includeTime: true),
      ),
      if (item.end != null)
        _InfoTile(
          icon: Icons.schedule_outlined,
          label: loc.end,
          value: fmtDate(context, item.end, includeTime: true),
        ),
      ..._kindSpecificRows(context, item),
      if (item.price != null)
        _InfoTile(
          icon: Icons.payments_outlined,
          label: loc.price,
          value: fmtMoney(context, item.price, currency: item.currency),
        ),
      if (item.price == null && (item.currency ?? '').isNotEmpty)
        _InfoTile(
          icon: Icons.currency_exchange_outlined,
          label: loc.currencyOptional,
          value: item.currency!,
        ),
      if ((item.recordLocator ?? '').isNotEmpty)
        _InfoTile(
          icon: Icons.receipt_long_outlined,
          label: loc.bookingNumberOptional,
          value: item.recordLocator!,
        ),
      if ((item.notes ?? '').isNotEmpty)
        _InfoTile(
          icon: Icons.notes_outlined,
          label: loc.notesOptional,
          value: item.notes!,
        ),
    ];
  }

  List<Widget> _kindSpecificRows(BuildContext context, TravelItem item) {
    final loc = AppLocalizations.of(context)!;

    switch (item.kind) {
      case TravelKind.flight:
        final flight = item as FlightItem;
        return [
          if ((flight.carrier ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.airlines_outlined,
              label: loc.airlineOptional,
              value: flight.carrier!,
            ),
          if ((flight.flightNo ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.flight_outlined,
              label: loc.flightnumber,
              value: flight.flightNo!,
            ),
        ];
      case TravelKind.train:
        return const [];
      case TravelKind.transfer:
        final transfer = item as TransferItem;
        return [
          if (transfer.mode != null)
            _InfoTile(
              icon: Icons.alt_route_outlined,
              label: loc.modeOptional,
              value: _formatTransferMode(context, transfer.mode!),
            ),
        ];
      case TravelKind.rentalCar:
        final rentalCar = item as RentalCarItem;
        return [
          if ((rentalCar.company ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.directions_car_outlined,
              label: loc.rentalCarCompany,
              value: rentalCar.company!,
            ),
        ];
      case TravelKind.hotel:
        final hotel = item as HotelItem;
        return [
          if ((hotel.company ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.business_outlined,
              label: loc.travelCompany,
              value: hotel.company!,
            ),
          if (hotel.name.isNotEmpty)
            _InfoTile(
              icon: Icons.hotel_outlined,
              label: loc.hotel,
              value: hotel.name,
            ),
          if ((hotel.location ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.location_city_outlined,
              label: loc.location,
              value: hotel.location!,
            ),
          if ((hotel.address ?? '').isNotEmpty)
            _InfoTile(
              icon: Icons.home_work_outlined,
              label: loc.travelAddressDetails,
              value: hotel.address!,
            ),
        ];
      case TravelKind.cruiseCheckIn:
        return const [];
      case TravelKind.cruiseCheckOut:
        return const [];
    }
  }
  
  String _formatTransferMode(BuildContext context, TransferMode mode) {
    final loc = AppLocalizations.of(context)!;
    switch (mode) {
      case TransferMode.shuttle:
        return loc.transferModeShuttle;
      case TransferMode.taxi:
        return loc.transferModeTaxi;
      case TransferMode.privateDriver:
        return loc.transferModePrivateDriver;
      case TransferMode.rideshare:
        return loc.transferModeRideshare;
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
