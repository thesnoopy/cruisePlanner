// RouteListScreen – list & edit route items with rich subtitles.
import 'package:flutter/material.dart';
import '../../store/cruise_store.dart';
import '../../models/cruise.dart';
import '../../models/route/port_call_item.dart';
import '../../models/route/sea_day_item.dart';
import '../../models/temporal_list_item.dart';
import '../../models/identifiable.dart';
import '../../utils/format.dart';
import 'route_edit_screen.dart';
import 'port_call_detail_screen.dart';
import 'sea_day_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../models/route/route_item.dart';
import '../../widgets/temporal_list_item_style.dart';

class RouteListScreen extends StatefulWidget {
  final String cruiseId;
  final DateTime Function()? nowProvider;

  const RouteListScreen({
    super.key,
    required this.cruiseId,
    this.nowProvider,
  });

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  Cruise? _cruise;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  bool _didAttemptInitialAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = CruiseStore();
    await s.load();
    setState(() => _cruise = s.getCruise(widget.cruiseId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialTargetIfNeeded();
    });
  }

  Future<void> _showCreateMenu() async {
    final loc = AppLocalizations.of(context)!;
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.directions_boat),
              title: Text(loc.harbour),
              onTap: () => Navigator.pop(c, 'port'),
            ),
            ListTile(
              leading: const Icon(Icons.waves),
              title: Text(loc.seaDay),
              onTap: () => Navigator.pop(c, 'sea'),
            ),
          ],
        ),
      ),
    );
    if (type == null) {
      return;
    }

    final s = CruiseStore();
    await s.load();
    final cruise = s.getCruise(widget.cruiseId);
    if (cruise == null) {
      return;
    }

    final id = Identifiable.newId();
    final date = cruise.period.start;

    if (type == 'port') {
      final item = PortCallItem(
        id: id,
        date: date,
        portName: '',
        arrival: null,
        departure: null,
        allAboard: null,
        notes: null,
      );
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    } else {
      final item = SeaDayItem(
        id: id,
        date: date,
        notes: null,
      );
      await s.upsertRouteItem(cruiseId: cruise.id, item: item);
    }

    await _load();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RouteEditScreen(routeItemId: id, cruiseId: widget.cruiseId),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cruise = _cruise;
    final routeItems = cruise == null
        ? <RouteItem>[]
        : [...cruise.route]..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: Text(loc.route)),
      body: routeItems.isEmpty
          ? Center(child: Text(loc.noHarbour))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: routeItems
                    .map((item) => _buildRouteItemCard(context, item))
                    .toList(growable: false),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        child: const Icon(Icons.add),
      ),
    );
  }


  void _scrollToInitialTargetIfNeeded() {
    if (_didAttemptInitialAutoScroll || !mounted) {
      return;
    }

    _didAttemptInitialAutoScroll = true;
    final cruise = _cruise;
    if (cruise == null) {
      return;
    }

    final routeItems = [...cruise.route]..sort((a, b) => a.date.compareTo(b.date));
    final now = _now();
    final targetIndex = temporalScrollTargetIndex<RouteItem>(
      routeItems,
      now,
      (item, currentNow) => item.temporalStatusAt(currentNow),
    );
    if (targetIndex == null) {
      return;
    }

    final target = routeItems[targetIndex];
    final contextForTarget = _itemKeys[target.id]?.currentContext;
    if (contextForTarget == null) {
      return;
    }

    Scrollable.ensureVisible(
      contextForTarget,
      alignment: 0.05,
      duration: Duration.zero,
    );
  }

  DateTime _now() => widget.nowProvider?.call() ?? DateTime.now();

  Widget _buildRouteItemCard(BuildContext context, RouteItem r) {
    final status = r.temporalStatusAt(_now());
    final cardColor = temporalListItemCardColor(context, status);
    final cardShape = temporalListItemCardShape(context, status);
    final contentColor = temporalListItemContentColor(context, status);
    final itemKey = _itemKeys.putIfAbsent(r.id, GlobalKey.new);

    if (r is PortCallItem) {
      return Card(
        key: itemKey,
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: cardShape,
        elevation: 2,
        child: InkWell(
          borderRadius: temporalListItemCardBorderRadius,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PortCallDetailScreen(
                  routeItemId: r.id,
                ),
              ),
            );
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.portName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: contentColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildPortSubtitle(
                        context,
                        r,
                        contentColor: contentColor,
                      ),
                    ],
                  ),
                ),
                if (status == TemporalListItemStatus.past) ...[
                  buildTemporalListItemStatusIcon(context, status),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final loc = AppLocalizations.of(context)!;
                    final s = CruiseStore();
                    await s.load();
                    if (!context.mounted) {
                      return;
                    }
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: loc.deleteRouteItemTitle,
                      message: loc.deleteRouteItemQuestionmark,
                      okText: loc.delete,
                      cancelText: loc.confirmCancel,
                      icon: Icons.warning_amber_rounded,
                      destructive: true,
                    );

                    if (!confirmed) {
                      return;
                    }
                    await s.deleteRouteItem(r.id);
                    await _load();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (r is SeaDayItem) {
      final loc = AppLocalizations.of(context)!;
      return Card(
        key: itemKey,
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: cardShape,
        elevation: 2,
        child: InkWell(
          borderRadius: temporalListItemCardBorderRadius,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeaDayDetailScreen(
                  routeItemId: r.id,
                ),
              ),
            );
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.waves,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.seaDay,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: contentColor),
                      ),
                      const SizedBox(height: 4),
                      _buildSeaDaySubtitle(
                        context,
                        r,
                        contentColor: contentColor,
                      ),
                    ],
                  ),
                ),
                if (status == TemporalListItemStatus.past) ...[
                  buildTemporalListItemStatusIcon(context, status),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final loc = AppLocalizations.of(context)!;
                    final s = CruiseStore();
                    await s.load();
                    if (!context.mounted) {
                      return;
                    }
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: loc.deleteRouteItemTitle,
                      message: loc.deleteRouteItemQuestionmark,
                      okText: loc.delete,
                      cancelText: loc.confirmCancel,
                      icon: Icons.warning_amber_rounded,
                      destructive: true,
                    );

                    if (!confirmed) {
                      return;
                    }
                    await s.deleteRouteItem(r.id);
                    await _load();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPortSubtitle(
    BuildContext context,
    PortCallItem r, {
    Color? contentColor,
  }) {
    final dateStr = fmtDate(context, r.date);
    final arrival = fmtDate(context, r.arrival, timeOnly: true);
    final departure = fmtDate(context, r.departure, timeOnly: true);
    final allAboard = fmtDate(context, r.allAboard, timeOnly: true);
    final loc = AppLocalizations.of(context)!;
    final stringArrival = loc.arrival;
    final stringdeparture = loc.departure;
    final stringallOnBoard = loc.allOnBoard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event, size: 14, color: contentColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(color: contentColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (arrival.isNotEmpty)
          Row(
            children: [
              Icon(Icons.login, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$stringArrival $arrival',
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (arrival.isNotEmpty) const SizedBox(height: 2),
        if (departure.isNotEmpty)
          Row(
            children: [
              Icon(Icons.logout, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$stringdeparture $departure',
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (departure.isNotEmpty) const SizedBox(height: 2),
        if (allAboard.isNotEmpty)
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$stringallOnBoard $allAboard',
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSeaDaySubtitle(
    BuildContext context,
    SeaDayItem r, {
    Color? contentColor,
  }) {
    final dateStr = fmtDate(context, r.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event, size: 14, color: contentColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                dateStr,
                style: TextStyle(color: contentColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (r.notes != null && r.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.notes, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  r.notes!,
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
