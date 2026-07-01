// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cruise Planner';

  @override
  String get homeTitle => 'Your cruises';

  @override
  String get homeNoCruises => 'No cruises yet. Tap + to add one.';

  @override
  String get homeNewCruiseLabel => 'New cruise';

  @override
  String get homeWebdavSettingsTooltip => 'WebDAV settings';

  @override
  String get homeCloudSyncTooltip => 'Cloud sync';

  @override
  String get homeCloudSyncNoStore => 'Cruise store not available – sync not possible.';

  @override
  String get homeCloudSyncNoWebdav => 'Please save WebDAV settings first.';

  @override
  String get homeCloudSyncDone => 'Cloud sync finished.';

  @override
  String homeCloudSyncFailed(String error) {
    return 'Cloud sync failed: $error';
  }

  @override
  String get homeDeleteTooltip => 'Delete';

  @override
  String get cruisePlanner => 'Cruise Planer';

  @override
  String get ship => 'Ship';

  @override
  String get cruise => 'Cruise';

  @override
  String get route => 'Itinerary';

  @override
  String get excursion => 'Shore excursion';

  @override
  String get travel => 'Travel';

  @override
  String get cruiseDetails => 'Cruise Details';

  @override
  String get unknownHarbour => 'Unknown Harbour';

  @override
  String get noHarbour => 'No Harbour today or in Future';

  @override
  String get arrival => 'Arrival';

  @override
  String get departure => 'Departure';

  @override
  String get allOnBoard => 'All on Board';

  @override
  String get noFutureExcursions => 'No Excursion';

  @override
  String get today => 'Today';

  @override
  String get pastStatusIconSemanticLabel => 'Past item';

  @override
  String get harbour => 'Port';

  @override
  String get meetingPoint => 'Meeting Point';

  @override
  String get price => 'Price';

  @override
  String get noTravelItem => 'No Travel Item';

  @override
  String get start => 'Departure';

  @override
  String get end => 'End';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get flight => 'Flight';

  @override
  String get train => 'Train';

  @override
  String get transfer => 'Transfer service';

  @override
  String get rentalCar => 'Rental Car';

  @override
  String get flightnumber => 'Flight Number';

  @override
  String get rentalCarCompany => 'Rental Car Company';

  @override
  String get title => 'Title';

  @override
  String get requiredField => 'Required Field';

  @override
  String get chatterOptional => 'Chatter (optional)';

  @override
  String get save => 'Save';

  @override
  String get seaDay => 'Sea Day';

  @override
  String get editPort => 'Edit Port';

  @override
  String get editSeaDay => 'Edit Seaday';

  @override
  String get date => 'Date';

  @override
  String get arrivalOptional => 'Arrival (optional)';

  @override
  String get departureOptional => 'Departure (optional)';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get allOnBoardOptional => 'All on Board (optional)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get newExcursion => 'New Excursion';

  @override
  String get noPort => 'No Port';

  @override
  String get stop => 'Stop';

  @override
  String get stops => 'Stops';

  @override
  String get addStop => 'Add stop';

  @override
  String get stopName => 'Name';

  @override
  String get visited => 'Visited';

  @override
  String get excursionNotFound => 'Excursion not found';

  @override
  String get excursions => 'Excursions';

  @override
  String get editExcursion => 'Edit Excursion';

  @override
  String get currencyOptional => 'Currency (optional)';

  @override
  String get editTravel => 'Edit Travel';

  @override
  String get editCruise => 'Edit Cruise';

  @override
  String get airlineOptional => 'Airline (optional)';

  @override
  String get bookingNumberOptional => 'Booking number (optional)';

  @override
  String get modeOptional => 'Mode (optional)';

  @override
  String get travelCompany => 'Company';

  @override
  String get travelAddressDetails => 'Address details';

  @override
  String get transferModeShuttle => 'Shuttle';

  @override
  String get transferModeTaxi => 'Taxi';

  @override
  String get transferModePrivateDriver => 'Private Driver';

  @override
  String get transferModeRideshare => 'Rideshare';

  @override
  String get editFlight => 'Edit Flight';

  @override
  String get editTrain => 'Edit Train';

  @override
  String get editRentalCar => 'Edit Rental Car';

  @override
  String get editTransfer => 'Edit Travel';

  @override
  String get cruiseCheckIn => 'Cruise Check-In';

  @override
  String get cruiseCheckOut => 'Cruise Check-Out';

  @override
  String get hotel => 'Hotel';

  @override
  String get cabinNumber => 'Cabin Number';

  @override
  String get deckNumber => 'Deck Number';

  @override
  String get deckname => 'Deck name';

  @override
  String get deposit => 'Deposit';

  @override
  String get finalPayment => 'Final Payment';

  @override
  String get noPaymentInformation => 'No payment information';

  @override
  String get fullyPayed => 'Fully paied';

  @override
  String get payOnBooking => 'Pay on Booking';

  @override
  String get stillOpen => 'still open';

  @override
  String get withoutDate => 'without Date';

  @override
  String get payed => 'payed';

  @override
  String get open => 'open';

  @override
  String get onSide => 'on side';

  @override
  String get amountPayableOnSide => 'The total amount is payable on-site';

  @override
  String get amountOnSide => 'The total amount is on-site';

  @override
  String get payment => 'Payment';

  @override
  String get paymentType => 'Payment Type';

  @override
  String get finalPaymentOnDate => 'Final Payment on Date';

  @override
  String get finalPaymentOnSide => 'Final Payment on Side';

  @override
  String get amountAlreadyPayed => 'Amount already paied';

  @override
  String get depositAlreadyPayed => 'Deposit already paied';

  @override
  String get remainingAmountOptional => 'Remaining amount (optional)';

  @override
  String get leaveEmptyForAutomaticCalculation => 'Leave empty for automatic calculation';

  @override
  String get remainingAmountDueUntill => 'remaining amount due untill';

  @override
  String get noDateSelected => 'No date selected';

  @override
  String get remainingAmountAlreadyPaied => 'remaining amount already paied';

  @override
  String get remainingAmountOnSide => 'Remaining amount on side';

  @override
  String get paymentTypesOnSide => 'Payment types on side';

  @override
  String get cash => 'Cash';

  @override
  String get credit => 'Credit';

  @override
  String get cashCurrency => 'Cash-currency';

  @override
  String get onlyLocalCurrency => 'Only local currency';

  @override
  String get localCurrencyOrOwnCurrency => 'Local currency or own currency';

  @override
  String get finalPaymentAlreadyPayed => 'Final payment already paied';

  @override
  String get fullPaymentOnSide => 'Full payment on side';

  @override
  String get confirmDefaultTitle => 'Confirm';

  @override
  String get confirmDefaultMessage => 'Do you want to proceed?';

  @override
  String get confirmOk => 'OK';

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get deleteExcursionTitle => 'Delete Excursion';

  @override
  String get deleteExcursionQuestionmark => 'Really delete excursion?';

  @override
  String get delete => 'delete';

  @override
  String get deleteCruiseTitle => 'Delete Cruise';

  @override
  String get deleteCruiseQuestionmark => 'Really delete this cruise?';

  @override
  String get deleteRouteItemTitle => 'Delete Port / Seeday';

  @override
  String get deleteRouteItemQuestionmark => 'Really delete this Port / Seeday?';

  @override
  String get deleteTravelItemTitle => 'Delete travel item';

  @override
  String get deleteTravelItemQuestionmark => 'Really delete this travel item?';

  @override
  String get location => 'Address';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get documents => 'Documents';

  @override
  String get attachExistingDocument => 'Attach existing document';

  @override
  String get importDocument => 'Import document';

  @override
  String get noLinkedDocuments => 'No linked documents.';

  @override
  String get noLinkedDocumentsForCruise => 'No documents linked to this cruise yet.';

  @override
  String get noLinkedDocumentsForExcursion => 'No documents linked to this excursion yet.';

  @override
  String get noAvailableDocumentsToAttach => 'No existing documents are available to attach.';

  @override
  String get detachDocument => 'Detach document';

  @override
  String get documentAttached => 'Document attached.';

  @override
  String get documentImported => 'Document imported.';

  @override
  String get documentLinkedExisting => 'Existing document linked.';

  @override
  String get documentAlreadyLinked => 'Document already linked.';

  @override
  String get documentImportFailed => 'Document import failed.';

  @override
  String get documentOpenFailed => 'Document could not be opened.';

  @override
  String get documentKindPdf => 'PDF';

  @override
  String get documentKindEmail => 'Email';

  @override
  String get documentKindImage => 'Image';

  @override
  String get documentKindUnknown => 'Document';

  @override
  String get urlSnapshotTitle => 'Save webpage as PDF';

  @override
  String get urlSnapshotHint =>
      'Open the relevant webpage in the app. When the visible state looks right, save it as a PDF document.';

  @override
  String get urlSnapshotUrlLabel => 'URL';

  @override
  String get urlSnapshotOpen => 'Open webpage';

  @override
  String get urlSnapshotReload => 'Reload';

  @override
  String get urlSnapshotSaveAsPdf => 'Save as PDF';

  @override
  String get urlSnapshotSaveAsPdfShort => 'URL as PDF';

  @override
  String get urlSnapshotMissingUrl => 'Please enter a valid URL.';

  @override
  String get urlSnapshotPageNotLoaded =>
      'The page has not finished loading yet and cannot be saved as a PDF.';

  @override
  String get urlSnapshotLoadFailed => 'The webpage could not be loaded.';
  @override
  String get urlSnapshotSaveFailed => 'The PDF could not be saved.';

  @override
  String get urlSnapshotUnsupportedPlatform =>
      'This feature is currently only available on Android and iOS.';

  @override
  String get sharePendingTitle => 'Pending shared items';

  @override
  String sharePendingSummary(int batchCount, int itemCount) {
    return '$batchCount batches waiting with $itemCount items.';
  }

  @override
  String sharePendingLatest(String summary) {
    return 'Latest: $summary';
  }

  @override
  String get sharePendingReviewAction => 'Review';

  @override
  String get sharePendingClearAllAction => 'Clear all';

  @override
  String sharePendingAdditionalItems(String label, int count) {
    return '$label and $count more';
  }

  @override
  String get shareReviewTitle => 'Shared items';

  @override
  String get shareReviewEmpty => 'No pending shared items right now.';

  @override
  String shareReviewBatchTitle(int itemCount) {
    return '$itemCount shared items';
  }

  @override
  String shareReviewReceivedAt(String receivedAt) {
    return 'Received $receivedAt';
  }

  @override
  String get shareReviewClearBatchAction => 'Clear';

  @override
  String get shareAssignAction => 'Assign';

  @override
  String get shareAssignTitle => 'Assign shared item';

  @override
  String get shareAssignSelectTarget => 'Choose where this shared item should go.';

  @override
  String get shareAssignUnsupported => 'This shared item type cannot be assigned yet.';

  @override
  String get shareAssignUnsupportedShort => 'Not yet supported';

  @override
  String get shareAssignItemUnavailable => 'This shared item is no longer available.';

  @override
  String get shareAssignNoTargets => 'No assignable targets are available yet.';

  @override
  String get shareAssignUrlOptionsTitle => 'How should this URL be added?';

  @override
  String get shareAssignUrlOptionsHint =>
      'You can attach the link as a document or also open the webpage and save the visible state as a PDF.';

  @override
  String get shareAssignAddLinkOnly => 'Add link only';

  @override
  String get shareAssignAddLinkAndSavePdf => 'Add link and save PDF';

  @override
  String get shareAssignUrlOpenBeforeSaveHint =>
      'The webpage will open. Review the visible state and then save it as a PDF.';

  @override
  String get shareAssignUrlAndPdfSaved => 'Link and PDF saved.';

  @override
  String get syncProgressTitle => 'Sync progress';

  @override
  String get syncProgressRunning => 'Synchronization in progress';

  @override
  String get syncProgressRunningDescription =>
      'The current synchronization is continuing in the background.';

  @override
  String get syncProgressCompleted => 'Synchronization completed';

  @override
  String get syncProgressCompletedDescription =>
      'All synchronization steps completed successfully.';

  @override
  String get syncProgressSkipped => 'Synchronization skipped';

  @override
  String get syncProgressSkippedDescription =>
      'WebDAV settings are missing or incomplete.';

  @override
  String get syncProgressFailed => 'Synchronization failed';

  @override
  String get syncProgressFailedDescription =>
      'Synchronization ended with errors.';

  @override
  String get syncProgressPreparing => 'Checking settings';

  @override
  String get syncProgressCruiseDataSync => 'Synchronizing cruise data';

  @override
  String get syncProgressDocumentMetadataAnalysis =>
      'Analyzing document metadata';

  @override
  String get syncProgressDocumentUploads => 'Uploading documents';

  @override
  String get syncProgressDocumentDownloads => 'Downloading documents';

  @override
  String get syncProgressLocalDocumentRecovery =>
      'Recovering local document files';

  @override
  String get syncProgressDeletionPropagation => 'Propagating deletions';

  @override
  String get syncProgressCleanup => 'Cleaning up deleted documents';

  @override
  String syncProgressItemCount(int count) {
    return intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 item',
      other: '$count items',
    );
  }

  @override
  String get syncProgressClose => 'Close';
}

