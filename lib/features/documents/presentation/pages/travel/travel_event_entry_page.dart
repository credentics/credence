import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/trip_event_category.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelEventEntryPage extends StatefulWidget {
  const TravelEventEntryPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    this.editDocumentId,
    CreateScannedDocument? createDocument,
    GetDocumentDetail? getDocumentDetail,
    UpdateDocument? updateDocument,
  }) : _createDocument = createDocument,
       _getDocumentDetail = getDocumentDetail,
       _updateDocument = updateDocument;

  final String tripId;
  final String tripTitle;
  final String? editDocumentId;
  final CreateScannedDocument? _createDocument;
  final GetDocumentDetail? _getDocumentDetail;
  final UpdateDocument? _updateDocument;

  @override
  State<TravelEventEntryPage> createState() => _TravelEventEntryPageState();
}

class _TravelEventEntryPageState extends State<TravelEventEntryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  final TextEditingController _transportNumberController =
      TextEditingController();
  final TextEditingController _seatController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _gateController = TextEditingController();

  final TextEditingController _stayPropertyController = TextEditingController();
  final TextEditingController _stayBookingPlatformController =
      TextEditingController();
  final TextEditingController _stayRoomTypeController = TextEditingController();
  final TextEditingController _stayGuestsController = TextEditingController(
    text: '2',
  );
  final TextEditingController _stayTotalController = TextEditingController();

  final TextEditingController _diningCuisineController =
      TextEditingController();
  final TextEditingController _diningGuestsController = TextEditingController(
    text: '2',
  );
  final TextEditingController _diningReservationController =
      TextEditingController();
  final TextEditingController _diningEstimatedController =
      TextEditingController();

  final TextEditingController _activityTypeController = TextEditingController();
  final TextEditingController _activityOrganizerController =
      TextEditingController();
  final TextEditingController _activityParticipantsController =
      TextEditingController(text: '1');
  final TextEditingController _activityPriceController =
      TextEditingController();
  final TextEditingController _activityBookingController =
      TextEditingController();

  final TextEditingController _reservationTypeController =
      TextEditingController(text: 'Car Rental');
  final TextEditingController _reservationProviderController =
      TextEditingController();
  final TextEditingController _reservationPickupController =
      TextEditingController();
  final TextEditingController _reservationReturnController =
      TextEditingController();
  final TextEditingController _reservationItemDetailsController =
      TextEditingController();
  final TextEditingController _reservationPriceController =
      TextEditingController();

  TripEventCategory _selectedCategory = TripEventCategory.travel;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _stayCheckIn;
  DateTime? _stayCheckOut;
  DateTime? _reservationPickupDateTime;
  DateTime? _reservationReturnDateTime;
  String _transportType = 'Flight';

  bool _isSaving = false;
  bool _isPickingTicket = false;
  bool _isPickingPdf = false;
  bool _isBootstrapping = false;
  String _ticketPath = '';
  String _pdfPath = '';
  int _existingDocumentsCount = 0;
  DocumentDetailEntity? _editingDetail;

  CreateScannedDocument get _createUseCase => widget._createDocument ?? getIt();
  GetDocumentDetail get _getDetailUseCase =>
      widget._getDocumentDetail ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();
  bool get _isEditMode => (widget.editDocumentId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _bootstrapFromExistingDocument();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _providerController.dispose();
    _confirmationController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _transportNumberController.dispose();
    _seatController.dispose();
    _terminalController.dispose();
    _gateController.dispose();
    _stayPropertyController.dispose();
    _stayBookingPlatformController.dispose();
    _stayRoomTypeController.dispose();
    _stayGuestsController.dispose();
    _stayTotalController.dispose();
    _diningCuisineController.dispose();
    _diningGuestsController.dispose();
    _diningReservationController.dispose();
    _diningEstimatedController.dispose();
    _activityTypeController.dispose();
    _activityOrganizerController.dispose();
    _activityParticipantsController.dispose();
    _activityPriceController.dispose();
    _activityBookingController.dispose();
    _reservationTypeController.dispose();
    _reservationProviderController.dispose();
    _reservationPickupController.dispose();
    _reservationReturnController.dispose();
    _reservationItemDetailsController.dispose();
    _reservationPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_isSaving &&
        !_isBootstrapping &&
        _titleController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty &&
        _eventDate != null;
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: _isEditMode
            ? '${context.l10n.commonEdit} Timeline Event'
            : context.l10n.travelTimelineAddEventTitle,
        titleStyle: TextStyle(
          fontSize: 19.5,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(top: BorderSide(color: palette.stroke)),
          ),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF1F57D4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF1F57D4,
              ).withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              _isEditMode
                  ? Icons.save_rounded
                  : Icons.add_circle_outline_rounded,
              size: 20,
            ),
            label: Text(
              _isSaving
                  ? context.l10n.commonSaving
                  : (_isEditMode
                        ? context.l10n.commonSave
                        : context.l10n.travelTimelineAddAction),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isBootstrapping
            ? const Center(child: CupertinoActivityIndicator(radius: 12))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                          label: context.l10n.travelTimelineCategoryTravel,
                          icon: Icons.flight_rounded,
                          category: TripEventCategory.travel,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          label: context.l10n.travelTimelineCategoryStay,
                          icon: Icons.bed_rounded,
                          category: TripEventCategory.stay,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          label: context.l10n.travelTimelineCategoryDining,
                          icon: Icons.restaurant_rounded,
                          category: TripEventCategory.dining,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          label: context.l10n.travelTimelineCategoryActivity,
                          icon: Icons.attractions_rounded,
                          category: TripEventCategory.activity,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          label: context.l10n.travelTimelineCategoryReservation,
                          icon: Icons.confirmation_number_rounded,
                          category: TripEventCategory.reservation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _commonSection(context),
                  const SizedBox(height: 12),
                  _specificSection(context),
                  const SizedBox(height: 12),
                  _documentsAndNotesSection(context),
                ],
              ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required TripEventCategory category,
  }) {
    return TravelCategoryChip(
      label: label,
      icon: icon,
      active: _selectedCategory == category,
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  Widget _commonSection(BuildContext context) {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Basic details'),
          const SizedBox(height: 10),
          _fieldLabel('Event Title'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelHintEventTitle,
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 10),
          _fieldLabel('Location / Address'),
          SizedBox(height: 6),
          TextField(
            controller: _locationController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelHintSearchLocation,
              suffixIcon: Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.map_rounded,
                  color: context.appPalette.primary,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _datePickerField(
                  label: 'Date',
                  value: _eventDate,
                  onTap: _pickEventDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timePickerField(
                  label: 'Time',
                  value: _eventTime,
                  onTap: _pickEventTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specificSection(BuildContext context) {
    return switch (_selectedCategory) {
      TripEventCategory.travel => _travelSpecificCard(),
      TripEventCategory.stay => _staySpecificCard(),
      TripEventCategory.dining => _diningSpecificCard(),
      TripEventCategory.activity => _activitySpecificCard(),
      TripEventCategory.reservation => _reservationSpecificCard(),
    };
  }

  Widget _travelSpecificCard() {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Travel details'),
          const SizedBox(height: 10),
          _fieldLabel('Transport Type'),
          const SizedBox(height: 7),
          Row(
            children: [
              _transportChip('Flight'),
              const SizedBox(width: 6),
              _transportChip('Train'),
              const SizedBox(width: 6),
              _transportChip('Car'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _departureController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldDeparture,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _arrivalController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldArrival,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _providerController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldAirlineProvider,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _transportNumberController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldFlightNo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _seatController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldSeat,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _terminalController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldTerminal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _gateController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldGate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fieldLabel('Confirmation / Booking Reference'),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmationController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelHintBookingRef,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staySpecificCard() {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Stay details'),
          const SizedBox(height: 10),
          _fieldLabel('Property Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _stayPropertyController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelHintHotelName,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _datePickerField(
                  label: 'Check-in',
                  value: _stayCheckIn,
                  onTap: _pickStayCheckIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _datePickerField(
                  label: 'Check-out',
                  value: _stayCheckOut,
                  onTap: _pickStayCheckOut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _confirmationController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldReservationNo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stayBookingPlatformController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldBookingPlatform,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stayRoomTypeController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldRoomType,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _stayGuestsController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldGuests,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _stayTotalController,
            style: travelInputTextStyle(context),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldTotalPrice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diningSpecificCard() {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Reservation details'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _diningCuisineController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldCuisineType,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _diningGuestsController,
                  style: travelInputTextStyle(context),
                  keyboardType: TextInputType.number,
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldGuests,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _diningReservationController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldReservationNo,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _diningEstimatedController,
                  style: travelInputTextStyle(context),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldEstimatedCost,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activitySpecificCard() {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Activity specifics'),
          const SizedBox(height: 10),
          TextField(
            controller: _activityTypeController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldActivityType,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _activityOrganizerController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldOrganizer,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _activityParticipantsController,
                  style: travelInputTextStyle(context),
                  keyboardType: TextInputType.number,
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldParticipants,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _activityPriceController,
                  style: travelInputTextStyle(context),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldTicketPrice,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _activityBookingController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldBookingReference,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reservationSpecificCard() {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Reservation details'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reservationTypeController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldReservationType,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _reservationProviderController,
                  style: travelInputTextStyle(context),
                  decoration: travelInputDecoration(
                    context,
                    hintText: context.l10n.travelFieldProvider,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reservationPickupController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldPickupLocation,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateTimeField(
                  label: 'Pickup Date & Time',
                  value: _reservationPickupDateTime,
                  onTap: _pickReservationPickupDateTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTimeField(
                  label: 'Return Date & Time',
                  value: _reservationReturnDateTime,
                  onTap: _pickReservationReturnDateTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmationController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldReservationNumber,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reservationItemDetailsController,
            style: travelInputTextStyle(context),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldVehicleDetails,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reservationPriceController,
            style: travelInputTextStyle(context),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelFieldPriceDeposit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsAndNotesSection(BuildContext context) {
    return TravelSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Documents & Notes'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TravelUploadActionButton(
                  label: _isPickingTicket
                      ? 'Picking...'
                      : _ticketPath.trim().isEmpty
                      ? 'Scan Ticket'
                      : _ticketPath.split(Platform.pathSeparator).last,
                  icon: Icons.document_scanner_rounded,
                  onTap: _pickTicket,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TravelUploadActionButton(
                  label: _isPickingPdf
                      ? 'Picking...'
                      : _pdfPath.trim().isEmpty
                      ? 'Upload PDF'
                      : _pdfPath.split(Platform.pathSeparator).last,
                  icon: Icons.picture_as_pdf_rounded,
                  onTap: _pickPdf,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fieldLabel('Additional Notes'),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            style: travelInputTextStyle(context),
            maxLines: 4,
            decoration: travelInputDecoration(
              context,
              hintText: context.l10n.travelHintNotes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportChip(String value) {
    final active = _transportType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transportType = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? context.appPalette.primary
                : context.appPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : context.appPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? context.l10n.idEntryDateFormatHint
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(value),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? context.appPalette.textMuted
                          : context.appPalette.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF7E90AB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '--:--' : value.format(context),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? context.appPalette.textMuted
                          : context.appPalette.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: Color(0xFF7E90AB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? '--'
                        : DateFormat('MMM d, HH:mm').format(value),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? context.appPalette.textMuted
                          : context.appPalette.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF7E90AB),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.appPalette.textPrimary,
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: context.appPalette.textSecondary,
      ),
    );
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _eventDate = picked;
    });
  }

  Future<void> _pickEventTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _eventTime = picked;
    });
  }

  Future<void> _pickStayCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _stayCheckIn ?? _eventDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _stayCheckIn = picked;
    });
  }

  Future<void> _pickStayCheckOut() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _stayCheckOut ?? _stayCheckIn ?? _eventDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _stayCheckOut = picked;
    });
  }

  Future<void> _pickReservationPickupDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reservationPickupDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reservationPickupDateTime ?? now),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _reservationPickupDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickReservationReturnDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate:
          _reservationReturnDateTime ?? _reservationPickupDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reservationReturnDateTime ?? now),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _reservationReturnDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickTicket() async {
    if (_isPickingTicket || _isSaving) {
      return;
    }
    setState(() {
      _isPickingTicket = true;
    });
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'ticket',
            extensions: [
              'jpg',
              'jpeg',
              'png',
              'pdf',
              'doc',
              'docx',
              'xls',
              'xlsx',
              'ppt',
              'pptx',
              'txt',
              'rtf',
              'csv',
            ],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'com.adobe.pdf',
              'org.openxmlformats.wordprocessingml.document',
              'com.microsoft.word.doc',
              'org.openxmlformats.spreadsheetml.sheet',
              'org.openxmlformats.presentationml.presentation',
              'public.plain-text',
              'public.rtf',
              'public.comma-separated-values-text',
            ],
          ),
        ],
      );
      if (picked == null) {
        return;
      }
      final persistedPath = await _persistTravelAssetFile(
        sourcePath: picked.path.trim(),
        prefix: 'travel_ticket',
      );
      if (persistedPath == null) {
        return;
      }
      setState(() {
        _ticketPath = persistedPath;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingTicket = false;
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    if (_isPickingPdf || _isSaving) {
      return;
    }
    setState(() {
      _isPickingPdf = true;
    });
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'pdf',
            extensions: ['pdf'],
            uniformTypeIdentifiers: ['com.adobe.pdf'],
          ),
        ],
      );
      if (picked == null) {
        return;
      }
      final persistedPath = await _persistTravelAssetFile(
        sourcePath: picked.path.trim(),
        prefix: 'travel_pdf',
      );
      if (persistedPath == null) {
        return;
      }
      setState(() {
        _pdfPath = persistedPath;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPdf = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final date = _eventDate;
    if (title.isEmpty || location.isEmpty || date == null) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final eventDateValue = DateFormat('yyyy-MM-dd').format(date);
      final eventTimeValue = _eventTime == null
          ? ''
          : '${_eventTime!.hour.toString().padLeft(2, '0')}:${_eventTime!.minute.toString().padLeft(2, '0')}';
      final provider = _resolvedProvider();
      final confirmation = _resolvedConfirmation();
      final documentPaths = <String>[
        if (_ticketPath.trim().isNotEmpty) _ticketPath.trim(),
        if (_pdfPath.trim().isNotEmpty) _pdfPath.trim(),
      ];
      final documentsCount = documentPaths.isEmpty
          ? _existingDocumentsCount
          : documentPaths.length;
      final previewImagePath = documentPaths.firstWhere(
        (path) =>
            path.toLowerCase().endsWith('.png') ||
            path.toLowerCase().endsWith('.jpg') ||
            path.toLowerCase().endsWith('.jpeg'),
        orElse: () => '',
      );

      final structuredFields = <Map<String, String>>[
        {'label': 'Trip ID', 'value': widget.tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeTimelineEvent},
        {'label': 'Event Category', 'value': _selectedCategory.key},
        {'label': 'Event Title', 'value': title},
        {'label': 'Location', 'value': location},
        {'label': 'Event Date', 'value': eventDateValue},
        {'label': 'Event Time', 'value': eventTimeValue},
        {'label': 'Provider', 'value': provider},
        {'label': 'Confirmation', 'value': confirmation},
        {'label': 'Documents Count', 'value': '$documentsCount'},
        {'label': 'Notes', 'value': _notesController.text.trim()},
        {'label': 'Transport Type', 'value': _transportType},
        {'label': 'Departure', 'value': _departureController.text.trim()},
        {'label': 'Arrival', 'value': _arrivalController.text.trim()},
        {
          'label': 'Transport Number',
          'value': _transportNumberController.text.trim(),
        },
        {'label': 'Seat', 'value': _seatController.text.trim()},
        {'label': 'Terminal', 'value': _terminalController.text.trim()},
        {'label': 'Gate', 'value': _gateController.text.trim()},
        {
          'label': 'Property Name',
          'value': _stayPropertyController.text.trim(),
        },
        {
          'label': 'Check-in',
          'value': _stayCheckIn == null
              ? ''
              : DateFormat('yyyy-MM-dd').format(_stayCheckIn!),
        },
        {
          'label': 'Check-out',
          'value': _stayCheckOut == null
              ? ''
              : DateFormat('yyyy-MM-dd').format(_stayCheckOut!),
        },
        {
          'label': 'Booking Platform',
          'value': _stayBookingPlatformController.text.trim(),
        },
        {'label': 'Room Type', 'value': _stayRoomTypeController.text.trim()},
        {'label': 'Guests', 'value': _stayGuestsController.text.trim()},
        {'label': 'Total Price', 'value': _stayTotalController.text.trim()},
        {
          'label': 'Cuisine Type',
          'value': _diningCuisineController.text.trim(),
        },
        {
          'label': 'Dining Guests',
          'value': _diningGuestsController.text.trim(),
        },
        {
          'label': 'Dining Reservation No.',
          'value': _diningReservationController.text.trim(),
        },
        {
          'label': 'Estimated Cost',
          'value': _diningEstimatedController.text.trim(),
        },
        {
          'label': 'Activity Type',
          'value': _activityTypeController.text.trim(),
        },
        {
          'label': 'Organizer',
          'value': _activityOrganizerController.text.trim(),
        },
        {
          'label': 'Participants',
          'value': _activityParticipantsController.text.trim(),
        },
        {
          'label': 'Ticket Price',
          'value': _activityPriceController.text.trim(),
        },
        {
          'label': 'Booking Reference',
          'value': _activityBookingController.text.trim(),
        },
        {
          'label': 'Reservation Type',
          'value': _reservationTypeController.text.trim(),
        },
        {
          'label': 'Reservation Provider',
          'value': _reservationProviderController.text.trim(),
        },
        {
          'label': 'Pickup Location',
          'value': _reservationPickupController.text.trim(),
        },
        {
          'label': 'Return Location',
          'value': _reservationReturnController.text.trim(),
        },
        {
          'label': 'Pickup Date Time',
          'value': _reservationPickupDateTime == null
              ? ''
              : DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(_reservationPickupDateTime!),
        },
        {
          'label': 'Return Date Time',
          'value': _reservationReturnDateTime == null
              ? ''
              : DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(_reservationReturnDateTime!),
        },
        {
          'label': 'Vehicle / Item Details',
          'value': _reservationItemDetailsController.text.trim(),
        },
        {
          'label': 'Price / Deposit',
          'value': _reservationPriceController.text.trim(),
        },
        {
          'label': DocumentMetadataFieldLabels.travelTripId,
          'value': widget.tripId,
        },
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeTimelineEvent,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventCategory,
          'value': _selectedCategory.key,
        },
        {'label': DocumentMetadataFieldLabels.travelTripTitle, 'value': title},
        {
          'label': DocumentMetadataFieldLabels.travelEventDate,
          'value': eventDateValue,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventTime,
          'value': eventTimeValue,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventLocation,
          'value': location,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventProvider,
          'value': provider,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventConfirmation,
          'value': confirmation,
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventDocumentsCount,
          'value': '$documentsCount',
        },
        {
          'label': DocumentMetadataFieldLabels.travelEventPreviewImagePath,
          'value': previewImagePath,
        },
        {
          'label': DocumentMetadataFieldLabels.travelNotes,
          'value': _notesController.text.trim(),
        },
        if (documentPaths.isNotEmpty) ...[
          {
            'label': DocumentMetadataFieldLabels.referenceAssetPath,
            'value': documentPaths.first,
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetName,
            'value': _fileName(documentPaths.first),
          },
          {
            'label': DocumentMetadataFieldLabels.frontImagePath,
            'value': documentPaths.first,
          },
          {
            'label': DocumentMetadataFieldLabels.previewImagePath,
            'value': documentPaths.first,
          },
        ],
      ].where((item) => (item['value'] ?? '').trim().isNotEmpty).toList();

      final tags = <String>{
        'Travel',
        'Timeline',
        _selectedCategory.key,
        ...(_editingDetail?.tags ?? const <String>[]),
      }.where((value) => value.trim().isNotEmpty).toList(growable: false);

      if (_isEditMode && _editingDetail != null) {
        await _updateUseCase(
          UpdateDocumentParams(
            documentId: _editingDetail!.id,
            type: _editingDetail!.type,
            source: _editingDetail!.captureSource,
            scanPagesCount: math.max(
              1,
              documentPaths.isEmpty
                  ? (_editingDetail!.scanPagesCount > 0
                        ? _editingDetail!.scanPagesCount
                        : documentsCount)
                  : documentPaths.length,
            ),
            categoryOverride: DocumentCategoryType.travel,
            documentTypeKeyOverride: 'travel_$_travelRecordTypeTimelineEvent',
            issuerOverride: title,
            identifierLabelOverride: 'Trip ID',
            identifierValueOverride: widget.tripId,
            tagsOverride: tags,
            structuredFieldsOverride: structuredFields,
          ),
        );
      } else {
        await _createUseCase(
          CreateScannedDocumentParams(
            type: DocumentType.other,
            source: DocumentCaptureSource.gallery,
            scanPagesCount: math.max(1, documentPaths.length),
            categoryOverride: DocumentCategoryType.travel,
            documentTypeKeyOverride: 'travel_$_travelRecordTypeTimelineEvent',
            issuerOverride: title,
            identifierLabelOverride: 'Trip ID',
            identifierValueOverride: widget.tripId,
            tagsOverride: tags,
            structuredFieldsOverride: structuredFields,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _persistTravelAssetFile({
    required String sourcePath,
    required String prefix,
  }) async {
    final normalized = sourcePath.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final originalName = normalized.split(RegExp(r'[\\/]')).last;
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: normalized,
      directoryName: 'travel_trip_assets',
      fileNamePrefix: '${prefix}_${_fileNameStem(originalName)}',
    );
  }

  String _fileNameStem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'file';
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return trimmed;
    return trimmed.substring(0, dot);
  }

  Future<void> _bootstrapFromExistingDocument() async {
    final documentId = (widget.editDocumentId ?? '').trim();
    if (documentId.isEmpty) {
      return;
    }
    setState(() {
      _isBootstrapping = true;
    });
    try {
      final detail = await _getDetailUseCase(
        GetDocumentDetailParams(documentId: documentId),
      );
      if (!mounted) {
        return;
      }
      final categoryRaw = _firstMatch(detail, const [
        DocumentMetadataFieldLabels.travelEventCategory,
        'Event Category',
        'category',
      ]);
      final selectedCategory = parseTripEventCategory(categoryRaw);
      final transportTypeRaw = _firstMatch(detail, const ['Transport Type']);
      final mappedTransportType = _normalizeTransportType(transportTypeRaw);
      final eventDate = _parseFlexibleDate(
        _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelEventDate,
          'Event Date',
          'date',
        ]),
      );
      final eventTime = _parseTimeOfDay(
        _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelEventTime,
          'Event Time',
          'time',
        ]),
      );
      final checkIn = _parseFlexibleDate(
        _firstMatch(detail, const ['Check-in']),
      );
      final checkOut = _parseFlexibleDate(
        _firstMatch(detail, const ['Check-out']),
      );
      final pickupDateTime = _parseFlexibleDateTime(
        _firstMatch(detail, const ['Pickup Date Time']),
      );
      final returnDateTime = _parseFlexibleDateTime(
        _firstMatch(detail, const ['Return Date Time']),
      );

      final parsedDocumentsCount = int.tryParse(
        _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelEventDocumentsCount,
          'Documents Count',
        ]),
      );

      var ticketPath = '';
      var pdfPath = '';
      final primaryPath = _firstMatch(detail, const [
        DocumentMetadataFieldLabels.referenceAssetPath,
        DocumentMetadataFieldLabels.frontImagePath,
      ]);
      final previewPath = _firstMatch(detail, const [
        DocumentMetadataFieldLabels.travelEventPreviewImagePath,
        DocumentMetadataFieldLabels.previewImagePath,
      ]);
      for (final candidate in <String>[primaryPath, previewPath]) {
        final value = candidate.trim();
        if (value.isEmpty) {
          continue;
        }
        if (_isImagePath(value) && ticketPath.isEmpty) {
          ticketPath = value;
        } else if (!_isImagePath(value) && pdfPath.isEmpty) {
          pdfPath = value;
        }
      }

      _editingDetail = detail;
      setState(() {
        _selectedCategory = selectedCategory;
        _transportType = mappedTransportType;

        _titleController.text = _firstMatch(detail, const [
          'Event Title',
          DocumentMetadataFieldLabels.travelTripTitle,
          'title',
        ]);
        _locationController.text = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelEventLocation,
          'Location',
          'Location / Address',
        ]);
        _notesController.text = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelNotes,
          'Notes',
        ]);

        _providerController.text = _firstMatch(detail, const ['Provider']);
        _confirmationController.text = _firstMatch(detail, const [
          'Confirmation',
          DocumentMetadataFieldLabels.travelEventConfirmation,
        ]);
        _departureController.text = _firstMatch(detail, const ['Departure']);
        _arrivalController.text = _firstMatch(detail, const ['Arrival']);
        _transportNumberController.text = _firstMatch(detail, const [
          'Transport Number',
        ]);
        _seatController.text = _firstMatch(detail, const ['Seat']);
        _terminalController.text = _firstMatch(detail, const ['Terminal']);
        _gateController.text = _firstMatch(detail, const ['Gate']);

        _stayPropertyController.text = _firstMatch(detail, const [
          'Property Name',
        ]);
        _stayBookingPlatformController.text = _firstMatch(detail, const [
          'Booking Platform',
        ]);
        _stayRoomTypeController.text = _firstMatch(detail, const ['Room Type']);
        _stayGuestsController.text = _firstMatch(detail, const [
          'Guests',
          'Number of Guests',
        ]);
        _stayTotalController.text = _firstMatch(detail, const ['Total Price']);

        _diningCuisineController.text = _firstMatch(detail, const [
          'Cuisine Type',
        ]);
        _diningGuestsController.text = _firstMatch(detail, const [
          'Dining Guests',
          'Guests',
        ]);
        _diningReservationController.text = _firstMatch(detail, const [
          'Dining Reservation No.',
        ]);
        _diningEstimatedController.text = _firstMatch(detail, const [
          'Estimated Cost',
        ]);

        _activityTypeController.text = _firstMatch(detail, const [
          'Activity Type',
        ]);
        _activityOrganizerController.text = _firstMatch(detail, const [
          'Organizer',
        ]);
        _activityParticipantsController.text = _firstMatch(detail, const [
          'Participants',
        ]);
        _activityPriceController.text = _firstMatch(detail, const [
          'Ticket Price',
        ]);
        _activityBookingController.text = _firstMatch(detail, const [
          'Booking Reference',
        ]);

        _reservationTypeController.text = _firstMatch(detail, const [
          'Reservation Type',
        ]);
        _reservationProviderController.text = _firstMatch(detail, const [
          'Reservation Provider',
        ]);
        _reservationPickupController.text = _firstMatch(detail, const [
          'Pickup Location',
        ]);
        _reservationReturnController.text = _firstMatch(detail, const [
          'Return Location',
        ]);
        _reservationItemDetailsController.text = _firstMatch(detail, const [
          'Vehicle / Item Details',
        ]);
        _reservationPriceController.text = _firstMatch(detail, const [
          'Price / Deposit',
        ]);

        _eventDate = eventDate;
        _eventTime = eventTime;
        _stayCheckIn = checkIn;
        _stayCheckOut = checkOut;
        _reservationPickupDateTime = pickupDateTime;
        _reservationReturnDateTime = returnDateTime;
        _ticketPath = ticketPath;
        _pdfPath = pdfPath;
        _existingDocumentsCount = (parsedDocumentsCount ?? 0) > 0
            ? parsedDocumentsCount!
            : detail.scanPagesCount;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.travelUnableLoadEvent)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  String _firstMatch(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      final canonicalTarget =
          DocumentMetadataFieldLabels.toCanonicalClaimKey(target) ??
          normalizedTarget;
      for (final field in detail.structuredFields) {
        final label = field.label.trim();
        final canonicalLabel = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          label,
        );
        final normalizedLabel = label.toLowerCase();
        if (normalizedLabel == normalizedTarget ||
            canonicalLabel == normalizedTarget ||
            canonicalLabel == canonicalTarget) {
          final value = field.value.trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return '';
  }

  DateTime? _parseFlexibleDate(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return null;
    }
    final asIso = DateTime.tryParse(raw);
    if (asIso != null) {
      return DateTime(asIso.year, asIso.month, asIso.day);
    }
    for (final pattern in const ['yyyy-MM-dd', 'MM/dd/yyyy', 'MMM d, yyyy']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(raw);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  DateTime? _parseFlexibleDateTime(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return null;
    }
    final asIso = DateTime.tryParse(raw);
    if (asIso != null) {
      return asIso;
    }
    for (final pattern in const ['yyyy-MM-dd HH:mm', 'yyyy-MM-dd hh:mm a']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  TimeOfDay? _parseTimeOfDay(String rawValue) {
    final value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([ap]m))?$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final marker = match.group(3);
    if (hour == null || minute == null || minute < 0 || minute > 59) {
      return null;
    }
    if (marker != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      if (marker == 'pm' && hour != 12) {
        hour += 12;
      }
      if (marker == 'am' && hour == 12) {
        hour = 0;
      }
    } else if (hour < 0 || hour > 23) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _isImagePath(String path) {
    final value = path.toLowerCase();
    return value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp');
  }

  String _normalizeTransportType(String rawValue) {
    final normalized = rawValue.trim().toLowerCase();
    if (normalized.contains('train')) {
      return 'Train';
    }
    if (normalized.contains('car')) {
      return 'Car';
    }
    return 'Flight';
  }

  String _resolvedProvider() {
    return switch (_selectedCategory) {
      TripEventCategory.travel => _providerController.text.trim(),
      TripEventCategory.stay => _stayBookingPlatformController.text.trim(),
      TripEventCategory.dining => _diningCuisineController.text.trim(),
      TripEventCategory.activity => _activityOrganizerController.text.trim(),
      TripEventCategory.reservation =>
        _reservationProviderController.text.trim(),
    };
  }

  String _resolvedConfirmation() {
    return switch (_selectedCategory) {
      TripEventCategory.travel => _confirmationController.text.trim(),
      TripEventCategory.stay => _confirmationController.text.trim(),
      TripEventCategory.dining => _diningReservationController.text.trim(),
      TripEventCategory.activity => _activityBookingController.text.trim(),
      TripEventCategory.reservation => _confirmationController.text.trim(),
    };
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0 || index == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(index + 1);
  }
}

const String _travelRecordTypeTimelineEvent = 'timeline_event';
