import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showMapAppPicker({
  required BuildContext context,
  required String address,
  String? title,
}) async {
  // 1) Geocoding
  final locations = await locationFromAddress(address);
  if (!context.mounted) return;

  if (locations.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adresse konnte nicht gefunden werden.')),
    );
    return;
  }

  final coords = Coords(locations.first.latitude, locations.first.longitude);

  // 2) Installierte Karten-Apps
  final maps = await MapLauncher.installedMaps;
  if (!context.mounted) return;

  if (maps.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keine Karten-App gefunden.')),
    );
    return;
  }

  Widget mapIcon(String assetPath) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(assetPath, width: 28, height: 28);
    }
    return Image.asset(assetPath, width: 28, height: 28);
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
          for (final map in maps)
            ListTile(
              leading: mapIcon(map.icon),
              title: Text(map.mapName),
              onTap: () async {
                Navigator.of(ctx).pop();

                // Directions ist i. d. R. das, was du willst:
                await map.showDirections(
                  destination: coords,
                  destinationTitle: address,
                );
              },
            ),
        ],
      ),
    ),
  );
}
