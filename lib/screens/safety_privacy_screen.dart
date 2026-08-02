import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/discreet_settings.dart';
import '../data/crisis/crisis_pack.dart';
import '../data/repositories/memory_safety_repository.dart';
import '../domain/repositories/safety_repository.dart';
import '../theme/safety_theme.dart';
import '../widgets/soft_surface.dart';
import 'legal_stub_screen.dart';

/// Sections of the Safety & Privacy hub that deep-links can target.
enum SafetyHubSection {
  overview,
  crisisResources,
  reportBlock,
  deleteData,
  yourData,
  messageProtection,
  legal,
}

/// Trust anchor — always reachable, never gated.
///
/// Reachable in ≤2 taps from Home (settings), Chat (crisis banner / overflow /
/// footer), Bookings (footer), and other screens via [SafetyQuickAccessBar].
class SafetyPrivacyScreen extends StatefulWidget {
  const SafetyPrivacyScreen({
    super.key,
    this.initialSection = SafetyHubSection.overview,
    this.safetyRepository,
    this.userId = 'local_user',
    this.crisisPackOverride,
    this.discreetSettings,
  });

  final SafetyHubSection initialSection;

  /// Real reports/blocks/delete pipeline (PR 16–17).
  final SafetyRepository? safetyRepository;

  final String userId;

  /// When set (tests), skips asset load.
  final CrisisPack? crisisPackOverride;

  /// Device privacy: discreet mode + app lock (PR 21).
  final DiscreetSettings? discreetSettings;

  @override
  State<SafetyPrivacyScreen> createState() => _SafetyPrivacyScreenState();
}

class _SafetyPrivacyScreenState extends State<SafetyPrivacyScreen> {
  final _scrollController = ScrollController();

  final _crisisKey = GlobalKey();
  final _reportKey = GlobalKey();
  final _dataKey = GlobalKey();
  final _protectionKey = GlobalKey();
  final _legalKey = GlobalKey();

  late final SafetyRepository _safety =
      widget.safetyRepository ?? MemorySafetyRepository();

  CrisisPack? _crisisPack;
  String? _crisisLoadError;

  // Report form
  String? _reportReason;
  final _reportDetailsController = TextEditingController();
  bool _reportSubmitting = false;
  bool _blocking = false;

  static const _reportReasons = <String>[
    'Unwanted or inappropriate messages',
    'Felt unsafe or pressured',
    'Spam or fake account',
    'Something else',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.crisisPackOverride != null) {
      _crisisPack = widget.crisisPackOverride;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.crisisPackOverride == null) {
        _loadCrisisPack();
      }
      _scrollToInitialSection();
    });
  }

  Future<void> _loadCrisisPack() async {
    if (widget.crisisPackOverride != null) {
      _crisisPack = widget.crisisPackOverride;
      return;
    }
    try {
      final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
      final pack = await CrisisPackLoader.loadForLocale(lang);
      if (!mounted) return;
      setState(() {
        _crisisPack = pack;
        _crisisLoadError = null;
      });
    } catch (e) {
      // Fallback EN if locale pack missing.
      try {
        final pack = await CrisisPackLoader.loadEnZw();
        if (!mounted) return;
        setState(() {
          _crisisPack = pack;
          _crisisLoadError = null;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _crisisLoadError = e2.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _reportDetailsController.dispose();
    super.dispose();
  }

  GlobalKey? _keyFor(SafetyHubSection section) {
    switch (section) {
      case SafetyHubSection.crisisResources:
        return _crisisKey;
      case SafetyHubSection.reportBlock:
        return _reportKey;
      case SafetyHubSection.deleteData:
      case SafetyHubSection.yourData:
        return _dataKey;
      case SafetyHubSection.messageProtection:
        return _protectionKey;
      case SafetyHubSection.legal:
        return _legalKey;
      case SafetyHubSection.overview:
        return null;
    }
  }

  void _scrollToInitialSection() {
    final key = _keyFor(widget.initialSection);
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _submitReport() async {
    if (_reportReason == null || _reportSubmitting) return;
    setState(() => _reportSubmitting = true);

    await _safety.submitReport(
      reporterId: widget.userId,
      targetType: 'listener',
      targetId: 'listener_unspecified',
      reason: _reportReason!,
      details: _reportDetailsController.text.trim().isEmpty
          ? null
          : _reportDetailsController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _reportSubmitting = false;
      _reportReason = null;
      _reportDetailsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Report received. We’ll review it. You can keep using the app.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _blockListener() async {
    if (_blocking) return;
    setState(() => _blocking = true);
    final result = await _safety.blockTarget(
      blockerId: widget.userId,
      blockedId: 'listener_unspecified',
    );
    if (!mounted) return;
    setState(() => _blocking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Blocked. Active chats with them were ended (${result.sessionsEnded}).',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Download started (prototype). A real export will arrive here later.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteData() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DeleteDataDialog(),
    );

    if (shouldDelete != true || !mounted) return;

    final result = await _safety.requestDeleteMyData(widget.userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deletion started: ${result.messagesScrubbed} messages removed, '
          '${result.sessionsUnlinked} sessions closed. Account removal finishes within 24 hours.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalStubScreen.termsOfService(),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalStubScreen.privacyPolicy(),
      ),
    );
  }

  bool _isHighlighted(SafetyHubSection section) {
    final initial = widget.initialSection;
    if (initial == SafetyHubSection.overview) return false;
    if (section == SafetyHubSection.yourData) {
      return initial == SafetyHubSection.yourData ||
          initial == SafetyHubSection.deleteData;
    }
    return initial == section;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final themed = SafetyTheme.wrap(base);

    return Theme(
      data: themed,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Safety & Privacy'),
            ),
            // SingleChildScrollView + Column keeps every section mounted so
            // deep-links and tests can reach actions without lazy-build gaps.
            body: SoftGradientBackground(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TrustChip(label: 'Always available'),
                          const SizedBox(height: 12),
                          Text(
                            'A quiet place for tools that keep you safe and in control. '
                            'This app is confidential emotional support — not therapy, '
                            'not medical care, and not an emergency service.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.78),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                  // 1. Immediate danger / crisis
                  KeyedSubtree(
                    key: _crisisKey,
                    child: _SafetySection(
                      highlighted:
                          _isHighlighted(SafetyHubSection.crisisResources),
                      eyebrow: 'Crisis resources',
                      title: "If you're in immediate danger",
                      child: _CrisisSectionBody(
                        pack: _crisisPack,
                        loadError: _crisisLoadError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Report / block
                  KeyedSubtree(
                    key: _reportKey,
                    child: _SafetySection(
                      highlighted:
                          _isHighlighted(SafetyHubSection.reportBlock),
                      eyebrow: 'Report & block',
                      title: 'Report or block a listener',
                      child: _ReportForm(
                        reasons: _reportReasons,
                        selectedReason: _reportReason,
                        detailsController: _reportDetailsController,
                        submitting: _reportSubmitting,
                        onReasonChanged: (v) =>
                            setState(() => _reportReason = v),
                        onSubmit: _submitReport,
                        onBlock: _blockListener,
                        blocking: _blocking,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Your data
                  KeyedSubtree(
                    key: _dataKey,
                    child: _SafetySection(
                      highlighted: _isHighlighted(SafetyHubSection.yourData) ||
                          _isHighlighted(SafetyHubSection.deleteData),
                      title: 'Your data',
                      child: _YourDataSection(
                        onDownload: _downloadData,
                        onDelete: _confirmDeleteData,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Message protection
                  KeyedSubtree(
                    key: _protectionKey,
                    child: _SafetySection(
                      highlighted:
                          _isHighlighted(SafetyHubSection.messageProtection),
                      title: 'How your messages are protected',
                      child: const _MessageProtectionBody(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4b. Device privacy (PR 21)
                  if (widget.discreetSettings != null) ...[
                    _SafetySection(
                      title: 'On this device',
                      child: _DevicePrivacySection(
                        settings: widget.discreetSettings!,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Legal
                  KeyedSubtree(
                    key: _legalKey,
                    child: _SafetySection(
                      highlighted: _isHighlighted(SafetyHubSection.legal),
                      title: 'Legal',
                      child: _LegalLinks(
                        onTerms: _openTerms,
                        onPrivacy: _openPrivacy,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Section chrome ───────────────────────────────────────────────────────────

class _SafetySection extends StatelessWidget {
  const _SafetySection({
    required this.title,
    required this.child,
    this.eyebrow,
    this.highlighted = false,
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SoftCard(
      highlighted: highlighted,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── 1. Crisis ────────────────────────────────────────────────────────────────

class _CrisisSectionBody extends StatelessWidget {
  const _CrisisSectionBody({
    this.pack,
    this.loadError,
  });

  final CrisisPack? pack;
  final String? loadError;

  IconData _iconFor(String name) {
    switch (name) {
      case 'emergency':
        return Icons.emergency_outlined;
      case 'people':
        return Icons.people_outline;
      default:
        return Icons.support_agent_outlined;
    }
  }

  void _openResource(BuildContext context, CrisisResource resource) {
    final dial = resource.tel;
    final link = resource.url;
    final lines = <String>[resource.subtitle];
    if (dial != null) {
      lines.add('Call $dial from your phone dialer if you need this number.');
    }
    if (link != null) {
      lines.add('Visit: $link');
    }
    lines.add('This app is not an emergency service'
        '${dial != null ? ' and cannot place the call for you' : ''}.');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(resource.title),
        content: SelectableText(lines.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pack = this.pack;

    if (loadError != null && pack == null) {
      return Text(
        'Crisis resources failed to load. If you are in danger, use your '
        'phone dialer for local emergency services. This app is not an '
        'emergency service.',
        style: textTheme.bodyMedium?.copyWith(height: 1.45),
      );
    }

    if (pack == null) {
      return Text(
        'Loading crisis resources…',
        style: textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          pack.disclaimer,
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 8),
        Text(
          'Zimbabwe ${pack.locale.toUpperCase()} pack v${pack.version} · partner-reviewed metadata present',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < pack.resources.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SoftCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => _openResource(context, pack.resources[i]),
            child: Row(
              children: [
                Icon(
                  _iconFor(pack.resources[i].icon),
                  color: scheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.resources[i].title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pack.resources[i].subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                      ),
                      if (pack.resources[i].tel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tel: ${pack.resources[i].tel}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'This app is not an emergency service, not a medical service, '
            'and not a substitute for professional care. We cannot send help '
            'to your location.',
            style: textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteDataDialog extends StatefulWidget {
  const _DeleteDataDialog();

  @override
  State<_DeleteDataDialog> createState() => _DeleteDataDialogState();
}

class _DeleteDataDialogState extends State<_DeleteDataDialog> {
  final _deleteController = TextEditingController();

  @override
  void dispose() {
    _deleteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canConfirm = _deleteController.text.trim() == 'DELETE';

    return AlertDialog(
      title: const Text('Delete my data?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This permanently removes the following from this app. '
              'This cannot be undone in the prototype.',
              style: textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            const _DeleteConsequenceRow(
              icon: Icons.chat_bubble_outline,
              label: 'Messages and chat history',
            ),
            const _DeleteConsequenceRow(
              icon: Icons.event_outlined,
              label: 'Bookings and scheduled sessions',
            ),
            const _DeleteConsequenceRow(
              icon: Icons.favorite_border,
              label: 'Mood check-ins',
            ),
            const _DeleteConsequenceRow(
              icon: Icons.badge_outlined,
              label: 'Account nickname',
            ),
            const SizedBox(height: 12),
            Text(
              'Safety reports already submitted may be kept for a short '
              'time to protect others.',
              style: textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type DELETE to confirm',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deleteController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'DELETE',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep my data'),
        ),
        TextButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

class _DeleteConsequenceRow extends StatelessWidget {
  const _DeleteConsequenceRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.error.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Report form ───────────────────────────────────────────────────────────

class _ReportForm extends StatelessWidget {
  const _ReportForm({
    required this.reasons,
    required this.selectedReason,
    required this.detailsController,
    required this.submitting,
    required this.onReasonChanged,
    required this.onSubmit,
    required this.onBlock,
    this.blocking = false,
  });

  final List<String> reasons;
  final String? selectedReason;
  final TextEditingController detailsController;
  final bool submitting;
  final ValueChanged<String?> onReasonChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBlock;
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canSubmit = selectedReason != null && !submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tell us what happened. We’ll review reports carefully. '
          'You can keep using the app afterward.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Reason',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in reasons)
              FilterChip(
                label: Text(reason),
                selected: selectedReason == reason,
                onSelected: submitting
                    ? null
                    : (selected) {
                        onReasonChanged(selected ? reason : null);
                      },
                showCheckmark: false,
                selectedColor: scheme.primary.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: selectedReason == reason
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: selectedReason == reason
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selectedReason == reason
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outline.withValues(alpha: 0.28),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: detailsController,
          enabled: !submitting,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Details (optional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        // Exactly one primary action for this form
        FilledButton(
          onPressed: canSubmit
              ? () {
                  HapticFeedback.lightImpact();
                  onSubmit();
                }
              : null,
          child: Text(submitting ? 'Submitting…' : 'Submit report'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: (submitting || blocking)
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onBlock();
                },
          child: Text(blocking ? 'Blocking…' : 'Block this listener'),
        ),
      ],
    );
  }
}

// ─── 3. Your data ─────────────────────────────────────────────────────────────

class _YourDataSection extends StatelessWidget {
  const _YourDataSection({
    required this.onDownload,
    required this.onDelete,
  });

  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You control what stays here. These actions apply to your account '
          'on this device for the prototype.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        _DataActionButton(
          icon: Icons.download_outlined,
          label: 'Download my data',
          subtitle: 'Get a copy of your information',
          onTap: onDownload,
          emphasized: false,
        ),
        const SizedBox(height: 10),
        _DataActionButton(
          icon: Icons.delete_outline,
          label: 'Delete my data',
          subtitle: 'Remove your account data from this app',
          onTap: onDelete,
          emphasized: true,
        ),
      ],
    );
  }
}

class _DataActionButton extends StatelessWidget {
  const _DataActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = emphasized
        ? scheme.error.withValues(alpha: 0.35)
        : scheme.outline.withValues(alpha: 0.3);
    final iconColor = emphasized ? scheme.error : scheme.primary;

    return Material(
      color: scheme.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: emphasized ? scheme.error : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 4. Message protection ────────────────────────────────────────────────────

class _MessageProtectionBody extends StatelessWidget {
  const _MessageProtectionBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Same lock language as Chat app bar — honest until real E2E ships.
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              'Private conversation',
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Your 1:1 chats are private conversations between you and your '
          'assigned listener. Only people in the chat should see your messages. '
          'There are no public profiles, public message feeds, or open forums.',
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          'The lock icon and “Private conversation” label you see in chat are '
          'a confidentiality cue — not a claim of full end-to-end encryption. '
          'Today, messages use transport security (HTTPS) and server storage '
          'protection. True E2E cryptography may come later; until then we use '
          'honest wording instead of “encrypted.”',
          style: textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'You can report, block, or delete your data anytime from this hub.',
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

// ─── 4b. Device privacy ───────────────────────────────────────────────────────

class _DevicePrivacySection extends StatefulWidget {
  const _DevicePrivacySection({required this.settings});

  final DiscreetSettings settings;

  @override
  State<_DevicePrivacySection> createState() => _DevicePrivacySectionState();
}

class _DevicePrivacySectionState extends State<_DevicePrivacySection> {
  final _pinController = TextEditingController();
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _toggleLock(bool enable) async {
    if (enable) {
      final pin = _pinController.text;
      final ok = await widget.settings.enableAppLock(pin);
      if (!ok) {
        setState(() => _pinError = 'Enter a 4-digit PIN to enable lock.');
        return;
      }
      setState(() => _pinError = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App lock on. You’ll need your PIN after restart.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final ok = widget.settings.verifyPin(_pinController.text);
      if (!ok) {
        setState(() => _pinError = 'Enter current PIN to turn lock off.');
        return;
      }
      await widget.settings.disableAppLock(currentPin: _pinController.text);
      setState(() => _pinError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'For shared phones at home. Discreet mode hides the app name; '
              'app lock asks for a PIN. Notification text stays hidden by default.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Discreet mode'),
              subtitle: Text(
                settings.discreetMode
                    ? 'App title shows as “Notes”'
                    : 'Show normal app name',
              ),
              value: settings.discreetMode,
              onChanged: (v) => settings.setDiscreetMode(v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('App lock'),
              subtitle: Text(
                settings.appLockEnabled
                    ? 'PIN required when the app opens'
                    : 'Off — set a 4-digit PIN below to enable',
              ),
              value: settings.appLockEnabled,
              onChanged: (v) => _toggleLock(v),
            ),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: '4-digit PIN',
                counterText: '',
                errorText: _pinError,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── 5. Legal ─────────────────────────────────────────────────────────────────

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({
    required this.onTerms,
    required this.onPrivacy,
  });

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.description_outlined, color: scheme.primary),
          title: Text('Terms of Service', style: textTheme.titleMedium),
          subtitle: const Text('How the app works (prototype)'),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          onTap: onTerms,
        ),
        Divider(height: 1, color: scheme.outline.withValues(alpha: 0.25)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.policy_outlined, color: scheme.primary),
          title: Text('Privacy Policy', style: textTheme.titleMedium),
          subtitle: const Text('How we handle your information (prototype)'),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          onTap: onPrivacy,
        ),
      ],
    );
  }
}
