enum UrlDocumentTargetType {
  cruise,
  excursion,
  travelItem,
  portCall,
  seaDay,
}

class UrlDocumentTarget {
  const UrlDocumentTarget({
    required this.type,
    required this.id,
  });

  final UrlDocumentTargetType type;
  final String id;
}

