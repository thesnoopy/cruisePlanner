
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/cruise.dart';
import '../../models/excursion.dart';
import '../../models/temporal_list_item.dart';
import '../../models/excursions/excursion_payment_status_extension.dart';
import '../../models/excursions/excursion_payment_trigger.dart';
import '../../models/excursions/excursion_payment_method.dart';
import '../../models/excursions/cash_currency_preference.dart';
import '../../screens/excursions/excursion_detail_screen.dart';
import '../../screens/excursions/excursion_edit_screen.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../store/cruise_store.dart';
import '../../utils/format.dart';
import '../../models/identifiable.dart';
import '../../widgets/temporal_list_item_style.dart';

class ExcursionListScreen extends StatefulWidget {
  final String cruiseId;
  final DateTime Function()? nowProvider;

  const ExcursionListScreen({
    super.key,
    required this.cruiseId,
    this.nowProvider,
  });

  @override
  State<ExcursionListScreen> createState() => _ExcursionListScreenState();
}

class _ExcursionListScreenState extends State<ExcursionListScreen> {
  Cruise? _cruise;
  bool _loading = true;
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  bool _didAttemptInitialAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = CruiseStore();
    await store.load();

    final cruise = store.getCruise(widget.cruiseId);

    if (!mounted) {
      return;
    }

    setState(() {
      _cruise = cruise;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialTargetIfNeeded();
    });
  }

  Future<void> _openDetail(Excursion ex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionDetailScreen(
          cruiseId: widget.cruiseId,
          excursionId: ex.id,
        ),
      ),
    );
    await _load();
  }

  // ADDED — neuer Ausflug
  Future<void> _createExcursion() async {
    final store = CruiseStore();
    await store.load();
    final cruise = store.getCruise(widget.cruiseId);
    if (cruise == null) {
      return;
    }

    final newExc = Excursion(
      id: Identifiable.newId(),
      title: '',
      date: cruise.period.start,
      port: null,
      meetingPoint: null,
      notes: null,
      price: null,
      currency: null,
      paymentPlan: null,
    );

    await store.upsertExcursion(
      cruiseId: cruise.id,
      excursion: newExc,
    );
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExcursionEditScreen(excursionId: newExc.id),
      ),
    );

    await _load();
  }

  // ADDED — Ausflug löschen
  Future<void> _deleteExcursion(String id) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showConfirmationDialog(
      context: context,
      title: loc.deleteExcursionTitle,              // optional
      message: loc.deleteExcursionQuestionmark, // optional
      okText: loc.delete,                     // optional
      cancelText: loc.confirmCancel,               // optional
      icon: Icons.warning_amber_rounded,     // optional
      destructive: true,                     // optional (OK Button rot)
    );

    if (!confirmed) {
      return;
    }

    final store = CruiseStore();
    await store.load();
    await store.deleteExcursion(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursions)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cruise = _cruise;

    if (cruise == null || cruise.excursions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.excursions)),
        body: Center(
          child: Text(loc.noFutureExcursions),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createExcursion,
          tooltip: loc.newExcursion,
          child: const Icon(Icons.add),
        ),
      );
    }

    final excursions = [...cruise.excursions]..sort(
        (a, b) => a.date.compareTo(b.date),
      );

    return Scaffold(
      appBar: AppBar(title: Text(loc.excursions)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: excursions
              .map((excursion) => _buildExcursionCard(context, excursion))
              .toList(growable: false),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createExcursion,
        tooltip: loc.newExcursion,
        child: const Icon(Icons.add),
      )
    );
  }

  void _scrollToInitialTargetIfNeeded() {
    if (_didAttemptInitialAutoScroll || !mounted || _loading) {
      return;
    }

    _didAttemptInitialAutoScroll = true;
    final cruise = _cruise;
    if (cruise == null) {
      return;
    }

    final excursions = [...cruise.excursions]
      ..sort((a, b) => a.date.compareTo(b.date));
    final now = _now();
    final targetIndex = temporalScrollTargetIndex<Excursion>(
      excursions,
      now,
      (item, currentNow) => item.temporalStatusAt(currentNow),
    );
    if (targetIndex == null) {
      return;
    }

    final contextForTarget = _itemKeys[excursions[targetIndex].id]?.currentContext;
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

  Widget _buildExcursionCard(BuildContext context, Excursion ex) {
    final status = ex.temporalStatusAt(_now());
    final cardColor = temporalListItemCardColor(context, status);
    final cardShape = temporalListItemCardShape(context, status);
    final contentColor = temporalListItemContentColor(context, status);
    final itemKey = _itemKeys.putIfAbsent(ex.id, GlobalKey.new);

    return Card(
      key: itemKey,
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: cardShape,
      child: InkWell(
        borderRadius: temporalListItemCardBorderRadius,
        onTap: () => _openDetail(ex),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.directions_walk,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: contentColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitle(
                      context,
                      ex,
                      contentColor: contentColor,
                      status: status,
                    ),
                  ],
                ),
              ),
              if (status == TemporalListItemStatus.past) ...[
                const SizedBox(width: 8),
                buildTemporalListItemStatusIcon(context, status),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteExcursion(ex.id),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    Excursion ex, {
    Color? contentColor,
    required TemporalListItemStatus status,
  }) {
    final dateLine = fmtDate(context, ex.date, includeTime: true);
    final portLine = ex.port?.isNotEmpty == true ? ex.port! : null;
    final paymentText = ex.paymentStatusText(context);
    final paymentIcons = _buildPaymentIcons(ex, status: status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              Icon(Icons.calendar_month, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateLine,
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (portLine != null) 
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  portLine,
                  style: TextStyle(color: contentColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.payments, size: 14, color: contentColor),
              const SizedBox(width: 4),
              Expanded( 
                child: Text(
                  paymentText,
                  style: TextStyle(color: contentColor),
                ),
              ),
            ],
          ),
        if (paymentIcons.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            children: paymentIcons,
          ),
        ],
      ],
    );
  }

  Widget _chipIcon(
    IconData icon,
    BuildContext context, {
    required TemporalListItemStatus status,
  }) {
    final isPast = status == TemporalListItemStatus.past;
    final color = isPast
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.tertiaryContainer;
    final foreground = isPast
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Theme.of(context).colorScheme.onTertiaryContainer;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: foreground),
    );
  }

  List<Widget> _buildPaymentIcons(
    Excursion ex, {
    required TemporalListItemStatus status,
  }) {
    final plan = ex.paymentPlan;
    if (plan == null || plan.parts.isEmpty) {
      return [];
    }

    final onSiteParts = plan.parts
        .where((p) => p.trigger == ExcursionPaymentTrigger.onSite)
        .toList();

    if (onSiteParts.isEmpty) {
      return [];
    }

    final p = onSiteParts.first;
    final methods = p.paymentMethods;

    final icons = <Widget>[];

    if (methods.contains(ExcursionPaymentMethod.cash)) {
      icons.add(_chipIcon(Icons.attach_money, context, status: status));
    }
    if (methods.contains(ExcursionPaymentMethod.creditCard)) {
      icons.add(_chipIcon(Icons.credit_card, context, status: status));
    }

    if (methods.contains(ExcursionPaymentMethod.cash) &&
        p.cashCurrencyPreference != null) {
      switch (p.cashCurrencyPreference) {
        case CashCurrencyPreference.localOnly:
          icons.add(_chipIcon(Icons.public, context, status: status));
          break;
        case CashCurrencyPreference.localOrHome:
          icons.add(_chipIcon(Icons.currency_exchange, context, status: status));
          break;
        default:
          break;
      }
    }

    return icons;
  }
}
