import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/auth/auth_service.dart';
import '../../services/sheets/sheets_service.dart';

// Extracts the spreadsheet ID from a full Google Sheets URL or returns the
// raw string if it looks like a bare ID already.
String? _extractSheetId(String input) {
  final trimmed = input.trim();
  // Full URL: https://docs.google.com/spreadsheets/d/<ID>/edit…
  final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
  if (match != null) return match.group(1);
  // Bare ID (44-char alphanumeric)
  if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(trimmed)) return trimmed;
  return null;
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  // 'choose' → 'names' → 'role' → 'date' → 'confirm'  (create flow)
  // 'choose' → 'connect'                                (connect flow)
  String _flow = 'choose';

  DateTime _weddingDate = DateTime.now().add(const Duration(days: 200));
  final _coupleName1 = TextEditingController();
  final _coupleName2 = TextEditingController();
  final _sheetUrlCtrl = TextEditingController();
  String _userRole = ''; // 'Bride' or 'Groom'

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _coupleName1.dispose();
    _coupleName2.dispose();
    _sheetUrlCtrl.dispose();
    super.dispose();
  }

  String get _coupleNames {
    final n1 = _coupleName1.text.trim();
    final n2 = _coupleName2.text.trim();
    if (n1.isEmpty && n2.isEmpty) return 'Our';
    if (n2.isEmpty) return n1;
    return '$n1 & $n2';
  }

  // ── Create new spreadsheet ─────────────────────────────────────────────────

  Future<void> _createSpreadsheet() async {
    setState(() { _busy = true; _error = null; });
    try {
      final client = await AuthService.instance.getAuthClient();
      if (client == null) throw Exception('Not signed in');
      final result = await SheetsService.createSpreadsheet(client, _coupleNames);
      await ref.read(settingsProvider.notifier).save(
            spreadsheetId: result.id,
            spreadsheetUrl: result.url,
            weddingDate: _weddingDate,
            coupleNames: _coupleNames,
            userRole: _userRole,
          );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  // ── Connect existing spreadsheet ───────────────────────────────────────────

  Future<void> _connectSpreadsheet() async {
    final id = _extractSheetId(_sheetUrlCtrl.text);
    if (id == null) {
      setState(() => _error = 'Could not read a spreadsheet ID from that URL. '
          'Copy the full link from Google Sheets and try again.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final url = 'https://docs.google.com/spreadsheets/d/$id';
      await ref.read(settingsProvider.notifier).save(
            spreadsheetId: id,
            spreadsheetUrl: url,
            weddingDate: _weddingDate,
            coupleNames: _coupleNames,
            userRole: _userRole,
          );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _busy = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weddingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.dustyRose),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _weddingDate = picked);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Set Up Your Planner', style: AppTextStyles.appBarTitle),
        leading: _flow != 'choose' && !_busy
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _error = null;
                    switch (_flow) {
                      case 'names': _flow = 'choose'; break;
                      case 'role': _flow = 'names'; break;
                      case 'date': _flow = 'role'; break;
                      case 'confirm': _flow = 'date'; break;
                      default: _flow = 'choose';
                    }
                  });
                },
              )
            : null,
        actions: [
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy ? _buildBusy() : _buildPage(),
        ),
      ),
    );
  }

  Widget _buildBusy() {
    final isConnect = _flow == 'connect';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.dustyRose),
        ),
        const SizedBox(height: 24),
        Text(
          isConnect
              ? 'Connecting to your spreadsheet…'
              : 'Creating your wedding planner spreadsheet…',
          style: AppTextStyles.cardTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isConnect
              ? 'Loading your existing data.'
              : 'This will appear in your Google Drive.',
          style: AppTextStyles.cardSubtitle,
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 24),
          Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => setState(() { _busy = false; _error = null; }),
            child: const Text('Go back'),
          ),
        ],
      ],
    );
  }

  Widget _buildPage() {
    switch (_flow) {
      case 'choose':  return _buildChoose();
      case 'names':   return _buildNames();
      case 'role':    return _buildRole();
      case 'date':    return _buildDate();
      case 'confirm': return _buildConfirm();
      case 'connect': return _buildConnect();
      default:        return _buildChoose();
    }
  }

  // ── Step: choose flow ──────────────────────────────────────────────────────

  Widget _buildChoose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Welcome!', style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Do you want to create a fresh planner, or connect to a spreadsheet you already have?',
          style: AppTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 32),
        _ChoiceCard(
          icon: Icons.add_chart_outlined,
          title: 'Create new planner',
          subtitle: 'Start fresh — we\'ll create a spreadsheet in your Google Drive.',
          onTap: () => setState(() => _flow = 'names'),
        ),
        const SizedBox(height: 16),
        _ChoiceCard(
          icon: Icons.link_outlined,
          title: 'Connect existing spreadsheet',
          subtitle: 'Already have a planner? Paste your Google Sheets link to reconnect.',
          onTap: () => setState(() => _flow = 'connect'),
        ),
      ],
    );
  }

  // ── Step: names (create flow) ──────────────────────────────────────────────

  Widget _buildNames() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 0, total: 4),
        const SizedBox(height: 28),
        Text("What are your names?", style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text("These will appear on your planner.", style: AppTextStyles.cardSubtitle),
        const SizedBox(height: 28),
        TextField(
          controller: _coupleName1,
          decoration: const InputDecoration(labelText: 'Your name'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _coupleName2,
          decoration: const InputDecoration(labelText: "Partner's name"),
          textCapitalization: TextCapitalization.words,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _flow = 'role'),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  // ── Step: role (create flow) ───────────────────────────────────────────────

  Widget _buildRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 1, total: 4),
        const SizedBox(height: 28),
        Text("Which role is yours?", style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text(
          "This personalises your task view and notifications.",
          style: AppTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 32),
        _RoleCard(
          role: 'Bride',
          icon: Icons.favorite,
          color: AppColors.dustyRose,
          selected: _userRole == 'Bride',
          onTap: () => setState(() => _userRole = 'Bride'),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          role: 'Groom',
          icon: Icons.diamond_outlined,
          color: AppColors.steelBlue,
          selected: _userRole == 'Groom',
          onTap: () => setState(() => _userRole = 'Groom'),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _userRole.isEmpty ? null : () => setState(() => _flow = 'date'),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  // ── Step: date (create flow) ───────────────────────────────────────────────

  Widget _buildDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 2, total: 4),
        const SizedBox(height: 28),
        Text("When is your wedding?", style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text("This powers the countdown and urgency system.", style: AppTextStyles.cardSubtitle),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dustyRose, width: 1.5),
              borderRadius: BorderRadius.circular(16),
              color: AppColors.dustyRose.withAlpha(15),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.dustyRose, size: 32),
                const SizedBox(height: 12),
                Text(
                  '${_weddingDate.day} ${_monthName(_weddingDate.month)} ${_weddingDate.year}',
                  style: AppTextStyles.displaySmall.copyWith(color: AppColors.dustyRose),
                ),
                const SizedBox(height: 4),
                Text('Tap to change', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _flow = 'confirm'),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  // ── Step: confirm (create flow) ────────────────────────────────────────────

  Widget _buildConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIndicator(current: 3, total: 4),
        const SizedBox(height: 28),
        Text("Ready to go!", style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text(
          "We'll create your wedding planner spreadsheet in Google Drive.",
          style: AppTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 32),
        _SummaryRow(label: 'Names', value: _coupleNames),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Your role', value: _userRole.isEmpty ? '—' : _userRole),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'Wedding date',
          value: '${_weddingDate.day} ${_monthName(_weddingDate.month)} ${_weddingDate.year}',
        ),
        const Spacer(),
        Text(
          'A spreadsheet titled "$_coupleNames Wedding Planner" will be created '
          'in your Google Drive and used to store all your wedding data.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _createSpreadsheet,
            child: const Text('Create My Planner'),
          ),
        ),
      ],
    );
  }

  // ── Step: connect existing ─────────────────────────────────────────────────

  Widget _buildConnect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Connect your spreadsheet', style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Open your existing planner in Google Sheets, copy the link from the address bar, and paste it below.',
          style: AppTextStyles.cardSubtitle,
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _sheetUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'Google Sheets URL',
            hintText: 'https://docs.google.com/spreadsheets/d/…',
            prefixIcon: Icon(Icons.link_outlined),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: 24),
        Text('Your names', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _coupleName1,
          decoration: const InputDecoration(labelText: 'Your name'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _coupleName2,
          decoration: const InputDecoration(labelText: "Partner's name"),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 24),
        Text('Your role', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: 'Bride',
                color: AppColors.dustyRose,
                selected: _userRole == 'Bride',
                onTap: () => setState(() => _userRole = 'Bride'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleChip(
                label: 'Groom',
                color: AppColors.steelBlue,
                selected: _userRole == 'Groom',
                onTap: () => setState(() => _userRole = 'Groom'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Wedding date', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  '${_weddingDate.day} ${_monthName(_weddingDate.month)} ${_weddingDate.year}',
                  style: AppTextStyles.bodyMedium,
                ),
                const Spacer(),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connectSpreadsheet,
            icon: const Icon(Icons.link),
            label: const Text('Connect'),
          ),
        ),
      ],
    );
  }

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dustyRose.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.dustyRose, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(role, style: AppTextStyles.cardTitle),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            height: 4,
            decoration: BoxDecoration(
              color: i <= current ? AppColors.dustyRose : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}
