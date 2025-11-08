import 'package:flutter/material.dart';
import '../store/cruise_store.dart';
import '../models/cruise.dart';
import 'cruise_details_page.dart';
import 'route_list_page.dart';
import 'excursion_list_page.dart';
import 'travel_list_page.dart';

class CruiseHubPage extends StatelessWidget {
  final Cruise cruise;
  final CruiseStore store;
  const CruiseHubPage({super.key, required this.cruise, required this.store});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _HubTile('Cruise Details', Icons.directions_boat, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CruiseDetailsPage(cruise: cruise, store: store),
        ));
      }),
      _HubTile('Route', Icons.map, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => RouteListPage(cruise: cruise, store: store),
        ));
      }),
      _HubTile('Excursions', Icons.flag, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ExcursionListPage(cruise: cruise, store: store),
        ));
      }),
      _HubTile('Travel', Icons.flight, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => TravelListPage(cruise: cruise, store: store),
        ));
      }),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(cruise.title)),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: tiles.map((t) => Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: t.onTap, child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon, size: 42),
              const SizedBox(height: 8),
              Text(t.title, style: Theme.of(context).textTheme.titleMedium),
            ]),
          )),
        )).toList(),
      ),
    );
  }
}

class _HubTile {
  final String title; final IconData icon; final VoidCallback onTap;
  _HubTile(this.title, this.icon, this.onTap);
}
