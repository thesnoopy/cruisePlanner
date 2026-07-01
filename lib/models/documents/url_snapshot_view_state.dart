class UrlSnapshotViewState {
  const UrlSnapshotViewState({
    required this.isSupported,
    required this.isLoading,
    required this.hasLoadedPage,
    required this.canCapture,
    this.currentUrl,
    this.pageTitle,
    this.errorMessage,
  });

  const UrlSnapshotViewState.initial({
    required bool isSupported,
  }) : this(
         isSupported: isSupported,
         isLoading: false,
         hasLoadedPage: false,
         canCapture: false,
       );

  final bool isSupported;
  final bool isLoading;
  final bool hasLoadedPage;
  final bool canCapture;
  final String? currentUrl;
  final String? pageTitle;
  final String? errorMessage;

  UrlSnapshotViewState copyWith({
    bool? isSupported,
    bool? isLoading,
    bool? hasLoadedPage,
    bool? canCapture,
    String? currentUrl,
    bool clearCurrentUrl = false,
    String? pageTitle,
    bool clearPageTitle = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return UrlSnapshotViewState(
      isSupported: isSupported ?? this.isSupported,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedPage: hasLoadedPage ?? this.hasLoadedPage,
      canCapture: canCapture ?? this.canCapture,
      currentUrl: clearCurrentUrl ? null : currentUrl ?? this.currentUrl,
      pageTitle: clearPageTitle ? null : pageTitle ?? this.pageTitle,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
