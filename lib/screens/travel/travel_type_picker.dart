import 'package:flutter/material.dart';
import 'package:cruise_app/gen/l10n/app_localizations.dart';
import 'package:cruise_app/models/travel.dart';

Future<TravelKind?> showTravelTypePicker(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet<TravelKind>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flight_takeoff),
              title: Text(t.travelKind_flight),
              onTap: () => Navigator.pop(ctx, TravelKind.flight),
            ),
            ListTile(
              leading: const Icon(Icons.train),
              title: Text(t.travelKind_train),
              onTap: () => Navigator.pop(ctx, TravelKind.train),
            ),
            ListTile(
              leading: const Icon(Icons.airport_shuttle),
              title: Text(t.travelKind_transfer),
              onTap: () => Navigator.pop(ctx, TravelKind.transfer),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(t.travelKind_rentalCar),
              onTap: () => Navigator.pop(ctx, TravelKind.rentalCar),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
