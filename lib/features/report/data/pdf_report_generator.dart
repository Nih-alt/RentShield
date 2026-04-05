import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../inspection/data/comparison_model.dart';
import 'report_data_builder.dart';
import 'report_model.dart';

/// Generates polished PDF reports from structured ReportData.
class PdfReportGenerator {
  // Brand colors mapped to PdfColor
  static const _primary = PdfColor.fromInt(0xFF1A2B3D);
  static const _primaryLight = PdfColor.fromInt(0xFF2D4356);
  static const _success = PdfColor.fromInt(0xFF22C55E);
  static const _warning = PdfColor.fromInt(0xFFF59E0B);
  static const _error = PdfColor.fromInt(0xFFEF4444);
  static const _info = PdfColor.fromInt(0xFF3B82F6);
  static const _textPrimary = PdfColor.fromInt(0xFF1A1F25);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const _textTertiary = PdfColor.fromInt(0xFF9CA3AF);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _background = PdfColor.fromInt(0xFFF7F8FA);
  static const _white = PdfColors.white;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, h:mm a');

  /// Generates a PDF file and returns the file path.
  Future<String> generate(ReportData data) async {
    final pdf = pw.Document(
      title: '${data.reportType.label} - ${data.propertyName}',
      author: 'Rent Shield',
      creator: 'Rent Shield App',
    );

    switch (data.reportType) {
      case ReportType.moveIn:
      case ReportType.moveOut:
        _buildSingleInspectionPdf(pdf, data);
      case ReportType.comparison:
        _buildComparisonPdf(pdf, data);
    }

    // Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/rent_shield_reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(data.generatedAt);
    final sanitizedName = data.propertyName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName =
        '${data.reportType.shortLabel}_${sanitizedName}_$timestamp.pdf';
    final filePath = '${reportsDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  // ─── Single Inspection PDF ────────────────────────────────────────

  void _buildSingleInspectionPdf(pw.Document pdf, ReportData data) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(data),
        footer: (context) => _buildPageFooter(context, data),
        build: (context) => [
          // Title block
          _buildTitleBlock(data),
          pw.SizedBox(height: 20),

          // Property & tenancy info
          _buildPropertySection(data),
          pw.SizedBox(height: 16),

          // Inspection overview
          _buildInspectionOverviewSection(data),
          pw.SizedBox(height: 16),

          // Stats summary
          _buildStatsSummary(data),
          pw.SizedBox(height: 20),

          // Room-by-room details
          _buildSectionTitle('Room-by-Room Details'),
          pw.SizedBox(height: 10),
          ...data.rooms.expand((room) => [
                _buildSingleRoomSection(room),
                pw.SizedBox(height: 12),
              ]),

          // Photos section
          if (data.selectedPhotoPaths.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _buildSectionTitle('Photo Evidence'),
            pw.SizedBox(height: 10),
            _buildPhotoGrid(data.selectedPhotoPaths),
          ],
        ],
      ),
    );
  }

  // ─── Comparison PDF ───────────────────────────────────────────────

  void _buildComparisonPdf(pw.Document pdf, ReportData data) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(data),
        footer: (context) => _buildPageFooter(context, data),
        build: (context) => [
          // Title block
          _buildComparisonTitleBlock(data),
          pw.SizedBox(height: 20),

          // Property & tenancy info
          _buildPropertySection(data),
          pw.SizedBox(height: 16),

          // Inspection dates
          _buildComparisonDates(data),
          pw.SizedBox(height: 16),

          // Comparison stats
          _buildComparisonStats(data),
          pw.SizedBox(height: 20),

          // Flagged issues
          if (data.flaggedItems.isNotEmpty) ...[
            _buildSectionTitle('Flagged Issues'),
            pw.SizedBox(height: 6),
            _buildSubtitle(
                'Items that worsened or developed new issues during tenancy'),
            pw.SizedBox(height: 10),
            _buildFlaggedIssuesTable(data.flaggedItems),
            pw.SizedBox(height: 20),
          ],

          // Room-by-room comparison
          _buildSectionTitle('Room-by-Room Comparison'),
          pw.SizedBox(height: 10),
          ...data.comparisonRooms.expand((room) => [
                _buildComparisonRoomSection(room),
                pw.SizedBox(height: 12),
              ]),

          // Photos section
          if (data.selectedPhotoPaths.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _buildSectionTitle('Photo Evidence'),
            pw.SizedBox(height: 10),
            _buildPhotoGrid(data.selectedPhotoPaths),
          ],
        ],
      ),
    );
  }

  // ─── Shared Building Blocks ───────────────────────────────────────

  pw.Widget _buildPageHeader(ReportData data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('RENT SHIELD',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
                letterSpacing: 2,
              )),
          pw.Text(data.reportType.label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _textTertiary,
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context, ReportData data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${_dateTimeFormat.format(data.generatedAt)}',
            style: const pw.TextStyle(fontSize: 7, color: _textTertiary),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _textTertiary),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitleBlock(ReportData data) {
    final date = data.inspectionDate != null
        ? _dateFormat.format(DateTime.parse(data.inspectionDate!))
        : '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${data.inspectionType} Inspection Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${data.propertyName} \u2022 $date',
            style: const pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFFB0BEC5)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildComparisonTitleBlock(ReportData data) {
    final hasIssues = data.worsenedCount > 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: hasIssues ? _error : _success,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Before & After Comparison Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            hasIssues
                ? '${data.worsenedCount} item${data.worsenedCount > 1 ? "s" : ""} worsened during tenancy'
                : 'No items worsened during tenancy',
            style: const pw.TextStyle(
                fontSize: 11, color: PdfColor.fromInt(0xFFFFFFE0)),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.propertyName,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPropertySection(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSmallSectionTitle('Property Details'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Name', data.propertyName),
          _buildInfoRow('Type', data.propertyType),
          _buildInfoRow('Address', data.propertyAddress),
          if (data.hasTenancy) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              height: 0.5,
              color: _border,
            ),
            pw.SizedBox(height: 10),
            _buildSmallSectionTitle('Tenancy Details'),
            pw.SizedBox(height: 8),
            if (data.landlordName != null)
              _buildInfoRow('Landlord',
                  '${data.landlordName}${data.landlordPhone != null ? " \u2022 ${data.landlordPhone}" : ""}'),
            if (data.tenancyRent != null)
              _buildInfoRow('Monthly Rent', '\u20B9${data.tenancyRent}'),
            if (data.tenancyDeposit != null)
              _buildInfoRow(
                  'Security Deposit', '\u20B9${data.tenancyDeposit}'),
            if (data.tenancyStart != null)
              _buildInfoRow('Tenancy Start',
                  _dateFormat.format(DateTime.parse(data.tenancyStart!))),
            if (data.tenancyEnd != null)
              _buildInfoRow('Tenancy End',
                  _dateFormat.format(DateTime.parse(data.tenancyEnd!))),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInspectionOverviewSection(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSmallSectionTitle('Inspection Overview'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Type', data.inspectionType ?? ''),
          if (data.inspectionDate != null)
            _buildInfoRow('Date',
                _dateFormat.format(DateTime.parse(data.inspectionDate!))),
          _buildInfoRow('Rooms', '${data.totalRooms}'),
          _buildInfoRow('Items Checked', '${data.totalItems}'),
          _buildInfoRow('Issues Found', '${data.totalIssues}'),
          _buildInfoRow('Photos', '${data.totalPhotos}'),
        ],
      ),
    );
  }

  pw.Widget _buildStatsSummary(ReportData data) {
    return pw.Row(
      children: [
        _buildStatBox('Good', '${data.okCount}', _success),
        pw.SizedBox(width: 8),
        _buildStatBox('Minor', '${data.minorCount}', _warning),
        pw.SizedBox(width: 8),
        _buildStatBox('Major', '${data.majorCount}', _error),
        pw.SizedBox(width: 8),
        _buildStatBox('Missing', '${data.missingCount}', _textTertiary),
      ],
    );
  }

  pw.Widget _buildComparisonDates(ReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Move-in Date',
                    style: const pw.TextStyle(
                        fontSize: 8, color: _textTertiary)),
                pw.SizedBox(height: 2),
                pw.Text(
                  data.moveInDate != null
                      ? _dateFormat.format(DateTime.parse(data.moveInDate!))
                      : 'N/A',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 30,
            alignment: pw.Alignment.center,
            child: pw.Text('\u2192',
                style: const pw.TextStyle(fontSize: 16, color: _textTertiary)),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Move-out Date',
                    style: const pw.TextStyle(
                        fontSize: 8, color: _textTertiary)),
                pw.SizedBox(height: 2),
                pw.Text(
                  data.moveOutDate != null
                      ? _dateFormat.format(DateTime.parse(data.moveOutDate!))
                      : 'N/A',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildComparisonStats(ReportData data) {
    return pw.Row(
      children: [
        _buildStatBox('Unchanged', '${data.unchangedCount}', _success),
        pw.SizedBox(width: 8),
        _buildStatBox('Worsened', '${data.worsenedCount}', _error),
        pw.SizedBox(width: 8),
        _buildStatBox('Improved', '${data.improvedCount}', _info),
        pw.SizedBox(width: 8),
        _buildStatBox('Rooms Changed', '${data.roomsWithChanges}', _warning),
      ],
    );
  }

  pw.Widget _buildFlaggedIssuesTable(List<ReportComparisonItemData> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            _tableHeader('Room'),
            _tableHeader('Item'),
            _tableHeader('Move-in'),
            _tableHeader('Move-out'),
            _tableHeader('Change'),
          ],
        ),
        // Data rows
        ...items.map((item) => pw.TableRow(
              children: [
                _tableCell(item.roomName),
                _tableCell(item.name),
                _tableCell(item.moveInCondition),
                _tableCell(item.moveOutCondition,
                    color: _error),
                _tableCell(item.changeLabel,
                    color: _error,
                    bold: true),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildSingleRoomSection(ReportRoomData room) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Room header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: room.hasIssues
                  ? const PdfColor.fromInt(0xFFFEF2F2)
                  : const PdfColor.fromInt(0xFFF0FDF4),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(room.name,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                pw.Text(
                  '${room.okCount} OK  ${room.minorCount} Minor  ${room.majorCount} Major  ${room.missingCount} Missing',
                  style: const pw.TextStyle(fontSize: 8, color: _textSecondary),
                ),
              ],
            ),
          ),
          // Items
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.3),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: _background),
                  children: [
                    _tableHeader('Item', color: _textPrimary),
                    _tableHeader('Category', color: _textPrimary),
                    _tableHeader('Condition', color: _textPrimary),
                    _tableHeader('Notes', color: _textPrimary),
                  ],
                ),
                ...room.items.map((item) => pw.TableRow(
                      children: [
                        _tableCell(item.name),
                        _tableCell(item.category,
                            fontSize: 7),
                        _tableCell(
                          item.conditionLabel,
                          color: item.hasIssue ? _error : _success,
                          bold: item.hasIssue,
                        ),
                        _tableCell(
                            item.notes ?? '-',
                            fontSize: 7),
                      ],
                    )),
              ],
            ),
          ),
          // Room notes
          if (room.notes != null && room.notes!.isNotEmpty)
            pw.Padding(
              padding:
                  const pw.EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: _background,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Room Notes',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _textSecondary)),
                    pw.SizedBox(height: 3),
                    pw.Text(room.notes!,
                        style: const pw.TextStyle(
                            fontSize: 8, color: _textPrimary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildComparisonRoomSection(ReportComparisonRoomData room) {
    final hasChanges = room.worsenedCount > 0 || room.improvedCount > 0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Room header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: hasChanges
                  ? const PdfColor.fromInt(0xFFFEF9C3)
                  : const PdfColor.fromInt(0xFFF0FDF4),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text(room.name,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold)),
                pw.Spacer(),
                pw.Text(
                  '${room.unchangedCount} same  ${room.worsenedCount} worse  ${room.improvedCount} better',
                  style: const pw.TextStyle(fontSize: 8, color: _textSecondary),
                ),
              ],
            ),
          ),
          // Items table
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.3),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: _background),
                  children: [
                    _tableHeader('Item', color: _textPrimary),
                    _tableHeader('Move-in', color: _textPrimary),
                    _tableHeader('Move-out', color: _textPrimary),
                    _tableHeader('Change', color: _textPrimary),
                  ],
                ),
                ...room.items.map((item) {
                  final changeColor = _changeTypeColor(item.changeType);
                  return pw.TableRow(
                    children: [
                      _tableCell(item.name),
                      _tableCell(item.moveInCondition),
                      _tableCell(item.moveOutCondition),
                      _tableCell(
                        item.changeLabel,
                        color: changeColor,
                        bold: item.isWorsened,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPhotoGrid(List<String> photoPaths) {
    final validPhotos = <pw.Widget>[];

    for (final path in photoPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          final bytes = file.readAsBytesSync();
          final image = pw.MemoryImage(bytes);
          validPhotos.add(
            pw.Container(
              width: 120,
              height: 90,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _border, width: 0.5),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
            ),
          );
        }
      } catch (_) {
        // Skip broken images silently
      }
    }

    if (validPhotos.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _background,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text('No photos available',
            style: const pw.TextStyle(fontSize: 9, color: _textTertiary)),
      );
    }

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: validPhotos,
    );
  }

  // ─── Helpers ────────────────────────────────────────────���─────────

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          )),
    );
  }

  pw.Widget _buildSmallSectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _primaryLight,
          letterSpacing: 0.5,
        ));
  }

  pw.Widget _buildSubtitle(String text) {
    return pw.Text(text,
        style: const pw.TextStyle(fontSize: 8, color: _textSecondary));
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 9, color: _textSecondary)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor(color.red, color.green, color.blue, 0.08),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: PdfColor(color.red, color.green, color.blue, 0.2),
            width: 0.5,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: color)),
          ],
        ),
      ),
    );
  }

  pw.Widget _tableHeader(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: color ?? _white,
          )),
    );
  }

  pw.Widget _tableCell(String text,
      {PdfColor? color, bool bold = false, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : null,
            color: color ?? _textPrimary,
          )),
    );
  }

  PdfColor _changeTypeColor(ChangeType type) {
    switch (type) {
      case ChangeType.unchanged:
        return _success;
      case ChangeType.worsened:
      case ChangeType.newIssue:
        return _error;
      case ChangeType.improved:
      case ChangeType.resolved:
        return _info;
    }
  }
}
