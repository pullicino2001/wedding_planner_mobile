import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/constants/app_constants.dart';
import '../models/team_member.dart';
import '../models/guest.dart';
import '../models/vendor.dart';
import '../models/checklist_item.dart';

class BriefPdfService {
  static const _teal = PdfColor.fromInt(0xFF0099AE);
  static const _tealDeep = PdfColor.fromInt(0xFF006064);
  static const _ink = PdfColor.fromInt(0xFF062A2E);
  static const _inkMute = PdfColor.fromInt(0xFF5E7E83);
  static const _line = PdfColor.fromInt(0xFFC5DEE3);
  static const _white = PdfColors.white;
  static const _danger = PdfColor.fromInt(0xFFC0524F);
  static const _warning = PdfColor.fromInt(0xFFD08A2E);
  static const _steelBlue = PdfColor.fromInt(0xFF5A80AA);

  Future<Uint8List> generate(
    TeamMember member,
    List<Guest> guests,
    List<Vendor> vendors,
    List<ChecklistItem> checklistItems,
    String coupleNames,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          _buildHeader(member),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                ..._buildDuties(member),
                ..._buildMyItems(member, checklistItems),
                if (member.pullsDietary) _buildDietary(guests),
                if (member.linkedVendorCategory.isNotEmpty)
                  _buildVendor(member.linkedVendorCategory, vendors),
                pw.SizedBox(height: 24),
                _buildFooter(coupleNames),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(TeamMember member) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(28, 28, 28, 22),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [PdfColor.fromInt(0xFF00C2D6), _teal, _tealDeep],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(
              color: const PdfColor(1, 1, 1, 0.2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: pw.TextStyle(
                color: _white,
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ROLE BRIEF',
                  style: pw.TextStyle(
                    color: const PdfColor(1, 1, 1, 0.7),
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  member.name,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (member.roleTitle.isNotEmpty)
                  pw.Text(
                    member.roleTitle,
                    style: pw.TextStyle(
                        color: const PdfColor(1, 1, 1, 0.85), fontSize: 12),
                  ),
                if (member.phone.isNotEmpty)
                  pw.Text(
                    member.phone,
                    style: pw.TextStyle(
                        color: const PdfColor(1, 1, 1, 0.85), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildDuties(TeamMember member) {
    final widgets = <pw.Widget>[];
    for (final phase in AppConstants.dutyPhases) {
      final duties = member.dutiesForPhase(phase);
      if (duties.isEmpty) continue;

      final phaseColor = phase == 'Church'
          ? _warning
          : phase == 'Venue'
              ? _teal
              : _steelBlue;

      widgets.add(pw.SizedBox(height: 16));
      widgets.add(_sectionHeader(
        '${phase.toUpperCase()} DUTIES',
        phaseColor,
      ));
      widgets.add(pw.SizedBox(height: 6));
      for (final d in duties) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 5, right: 8),
                  decoration: pw.BoxDecoration(
                    color: phaseColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(d.description,
                      style: pw.TextStyle(fontSize: 11, color: _ink)),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<pw.Widget> _buildMyItems(
      TeamMember member, List<ChecklistItem> checklistItems) {
    final myItems = checklistItems
        .where((i) =>
            i.personName.toLowerCase() == member.name.toLowerCase() &&
            i.personName.isNotEmpty)
        .toList();
    if (myItems.isEmpty) return [];

    final church =
        myItems.where((i) => i.destination == AppConstants.checklistChurch).toList();
    final venue =
        myItems.where((i) => i.destination == AppConstants.checklistVenue).toList();

    final widgets = <pw.Widget>[];
    widgets.add(pw.SizedBox(height: 16));
    widgets.add(_sectionHeader('YOUR ITEMS', _teal));
    widgets.add(pw.SizedBox(height: 6));

    void addGroup(String label, List<ChecklistItem> groupItems) {
      if (groupItems.isEmpty) return;
      widgets.add(pw.Text(label,
          style: pw.TextStyle(
              fontSize: 10, color: _inkMute, fontWeight: pw.FontWeight.bold)));
      widgets.add(pw.SizedBox(height: 4));
      for (final i in groupItems) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 3, right: 8),
                  decoration: pw.BoxDecoration(
                    color: _teal,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(i.item,
                      style: pw.TextStyle(fontSize: 11, color: _ink)),
                ),
                pw.Text(
                  'In Hand: ${i.inHand ? "✓" : "✗"}  Packed: ${i.packed ? "✓" : "✗"}',
                  style: pw.TextStyle(fontSize: 9, color: _inkMute),
                ),
              ],
            ),
          ),
        );
      }
    }

    addGroup('To Church:', church);
    if (church.isNotEmpty && venue.isNotEmpty) widgets.add(pw.SizedBox(height: 4));
    addGroup('To Venue:', venue);

    return widgets;
  }

  pw.Widget _buildDietary(List<Guest> guests) {
    final confirmed =
        guests.where((g) => g.rsvpStatus == AppConstants.rsvpConfirmed).toList();
    final withDietary = confirmed
        .where((g) => g.dietary.isNotEmpty && g.dietary.toLowerCase() != 'standard')
        .toList();

    final groups = <String, int>{};
    for (final g in withDietary) {
      final key = g.dietary.trim();
      groups[key] = (groups[key] ?? 0) + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        _sectionHeader('DIETARY REQUIREMENTS', _danger),
        pw.SizedBox(height: 6),
        pw.Text('Total confirmed: ${confirmed.length}',
            style: pw.TextStyle(fontSize: 11, color: _ink)),
        if (groups.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text('No special dietary requirements.',
                style: pw.TextStyle(fontSize: 11, color: _inkMute)),
          )
        else
          ...groups.entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      margin:
                          const pw.EdgeInsets.only(top: 3, right: 8),
                      decoration: pw.BoxDecoration(
                          color: _danger, shape: pw.BoxShape.circle),
                    ),
                    pw.Expanded(
                      child: pw.Text(e.key,
                          style: pw.TextStyle(fontSize: 11, color: _ink)),
                    ),
                    pw.Text('${e.value}',
                        style: pw.TextStyle(
                            fontSize: 11,
                            color: _danger,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
      ],
    );
  }

  pw.Widget _buildVendor(String category, List<Vendor> vendors) {
    final linked = vendors.where((v) => v.category == category).toList();
    if (linked.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        _sectionHeader('LINKED VENDOR — ${category.toUpperCase()}', _steelBlue),
        pw.SizedBox(height: 6),
        ...linked.map((v) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(v.name,
                      style: pw.TextStyle(
                          fontSize: 12,
                          color: _ink,
                          fontWeight: pw.FontWeight.bold)),
                  if (v.contactPerson.isNotEmpty)
                    _vendorRow('Contact', v.contactPerson),
                  if (v.phone.isNotEmpty) _vendorRow('Phone', v.phone),
                  if (v.email.isNotEmpty) _vendorRow('Email', v.email),
                  if (v.notes.isNotEmpty) _vendorRow('Notes', v.notes),
                ],
              ),
            )),
      ],
    );
  }

  pw.Widget _vendorRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 50,
              child: pw.Text('$label:',
                  style: pw.TextStyle(fontSize: 10, color: _inkMute)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(fontSize: 10, color: _ink)),
            ),
          ],
        ),
      );

  pw.Widget _sectionHeader(String title, PdfColor color) => pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 14,
            margin: const pw.EdgeInsets.only(right: 8),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      );

  pw.Widget _buildFooter(String coupleNames) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: _line, width: 1),
          ),
        ),
        child: pw.Center(
          child: pw.Text(
            '$coupleNames — Wedding Day Brief',
            style: pw.TextStyle(
              fontSize: 10,
              color: _inkMute,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
}
