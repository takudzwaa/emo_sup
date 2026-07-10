import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final SafetyHubSection initialSection;

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

  // Report form
  String? _reportReason;
  final _reportDetailsController = TextEditingController();
  bool _reportSubmitting = false;

  static const _reportReasons = <String>[
    'Unwanted or inappropriate messages',
    'Felt unsafe or pressured',
    'Spam or fake account',
    'Something else',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialSection();
    });
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

    // Prototype: local only. Later → reports/{reportId} in Firestore.
    await Future<void>.delayed(const Duration(milliseconds: 350));

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

  Future<void> _downloadData() async {
    // Prototype stub — no real export file yet.
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

    // Prototype: acknowledge only. Later → Cloud Function + Auth delete.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your data has been marked for deletion (prototype).'),
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
                      child: const _CrisisSectionBody(),
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

class _CrisisResource {
  const _CrisisResource({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _CrisisSectionBody extends StatelessWidget {
  const _CrisisSectionBody();

  static const _resources = <_CrisisResource>[
    _CrisisResource(
      icon: Icons.emergency_outlined,
      title: 'Local emergency services',
      subtitle: 'If you are in immediate danger, call 911 or your region’s number',
    ),
    _CrisisResource(
      icon: Icons.support_agent_outlined,
      title: 'Regional crisis lines',
      subtitle: 'Emotional crisis support available where you live',
    ),
    _CrisisResource(
      icon: Icons.people_outline,
      title: 'Someone you trust nearby',
      subtitle: 'A friend, family member, or local helper can sit with you',
    ),
  ];

  void _openResourceStub(BuildContext context, _CrisisResource resource) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(resource.title),
        content: Text(
          'In the full app this would open ${resource.title}. '
          'This prototype does not launch external links.\n\n'
          'This app is not an emergency service. If you need help right now, '
          'use your phone’s dialer or a trusted person nearby.',
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'If you are in immediate danger, reach real-world help first. '
          'These resources sit outside this app.',
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _resources.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SoftCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => _openResourceStub(context, _resources[i]),
            child: Row(
              children: [
                Icon(
                  _resources[i].icon,
                  color: scheme.primary,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resources[i].title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _resources[i].subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          height: 1.35,
                        ),
                      ),
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
  });

  final List<String> reasons;
  final String? selectedReason;
  final TextEditingController detailsController;
  final bool submitting;
  final ValueChanged<String?> onReasonChanged;
  final VoidCallback onSubmit;

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
        // Same lock language as Chat app bar
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),
            Text(
              'Encrypted',
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
          'assigned listener. In the product, messages are protected so that '
          'people outside your chat cannot read them.',
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          'The lock icon and “Encrypted” label you see in chat are the same '
          'cue used here — a reminder that this space is confidential. '
          '(In this prototype the cue is visual; full end-to-end cryptography '
          'is wired when we connect the live backend.)',
          style: textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'There are no public profiles, public message feeds, or open forums.',
          style: textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
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
