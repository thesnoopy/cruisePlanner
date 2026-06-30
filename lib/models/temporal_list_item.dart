import 'excursion.dart';
import 'route/port_call_item.dart';
import 'route/route_item.dart';
import 'route/sea_day_item.dart';
import 'travel/base_travel.dart';

enum TemporalListItemStatus { past, current, upcoming }

extension RouteItemTemporalStatus on RouteItem {
  TemporalListItemStatus temporalStatusAt(DateTime now) {
    if (this is PortCallItem) {
      final item = this as PortCallItem;
      final start = item.arrival ?? _startOfDay(item.date);
      final end = item.departure ?? _endOfDayExclusive(item.date);
      return _statusForRange(now: now, start: start, end: end);
    }

    if (this is SeaDayItem) {
      final item = this as SeaDayItem;
      return _statusForDateOnly(now: now, date: item.date);
    }

    return _statusForDateOnly(now: now, date: date);
  }
}

extension ExcursionTemporalStatus on Excursion {
  TemporalListItemStatus temporalStatusAt(DateTime now) {
    final start = date;
    final end = _endOfDayExclusive(date);
    return _statusForRange(now: now, start: start, end: end);
  }
}

extension TravelItemTemporalStatus on TravelItem {
  TemporalListItemStatus temporalStatusAt(DateTime now) {
    final start = this.start;
    final end = this.end ?? _endOfDayExclusive(start);
    return _statusForRange(now: now, start: start, end: end);
  }
}

int? temporalScrollTargetIndex<T>(
  List<T> items,
  DateTime now,
  TemporalListItemStatus Function(T item, DateTime now) statusOf,
) {
  for (var index = 0; index < items.length; index++) {
    if (statusOf(items[index], now) == TemporalListItemStatus.current) {
      return index;
    }
  }

  for (var index = 0; index < items.length; index++) {
    if (statusOf(items[index], now) == TemporalListItemStatus.upcoming) {
      return index;
    }
  }

  return null;
}

TemporalListItemStatus _statusForDateOnly({
  required DateTime now,
  required DateTime date,
}) {
  return _statusForRange(
    now: now,
    start: _startOfDay(date),
    end: _endOfDayExclusive(date),
  );
}

TemporalListItemStatus _statusForRange({
  required DateTime now,
  required DateTime start,
  required DateTime end,
}) {
  if (now.isBefore(start)) {
    return TemporalListItemStatus.upcoming;
  }
  if (!now.isBefore(end)) {
    return TemporalListItemStatus.past;
  }
  return TemporalListItemStatus.current;
}

DateTime _startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _endOfDayExclusive(DateTime value) =>
    DateTime(value.year, value.month, value.day + 1);
