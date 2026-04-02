enum DocumentKind {
  pdf,
  email,
  image,
  unknown,
  ;

  String get jsonValue {
    switch (this) {
      case DocumentKind.pdf:
        return 'pdf';
      case DocumentKind.email:
        return 'email';
      case DocumentKind.image:
        return 'image';
      case DocumentKind.unknown:
        return 'unknown';
    }
  }

  static DocumentKind fromJsonValue(Object? value) {
    switch (value) {
      case 'pdf':
        return DocumentKind.pdf;
      case 'email':
        return DocumentKind.email;
      case 'image':
        return DocumentKind.image;
      case 'unknown':
      default:
        return DocumentKind.unknown;
    }
  }
}
