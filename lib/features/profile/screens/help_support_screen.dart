import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);

  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.helpAndSupportTitle,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQ 섹션
              _buildSectionHeader(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: l10n.faqTitle,
              ),
              const SizedBox(height: 12),
              _buildFAQSection(context),

              const SizedBox(height: 24),

              // 문의하기 섹션
              _buildSectionHeader(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF10B981),
                title: l10n.contactUs,
              ),
              const SizedBox(height: 12),
              _buildContactSection(context),

              const SizedBox(height: 24),

              // 앱 정보 섹션
              _buildSectionHeader(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: l10n.appInfo,
              ),
              const SizedBox(height: 12),
              _buildAppInfoSection(context),

              const SizedBox(height: 24),

              // 법적 정보 섹션
              _buildSectionHeader(
                icon: Icons.gavel_rounded,
                iconColor: const Color(0xFF6B7280),
                title: l10n.legalInfo,
              ),
              const SizedBox(height: 12),
              _buildLegalSection(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = [
      {
        'question': l10n.faqAddRecord,
        'answer': l10n.faqAddRecordAnswer,
      },
      {
        'question': l10n.faqAddFavorite,
        'answer': l10n.faqAddFavoriteAnswer,
      },
      {
        'question': l10n.faqSchedule,
        'answer': l10n.faqScheduleAnswer,
      },
      {
        'question': l10n.faqNotification,
        'answer': l10n.faqNotificationAnswer,
      },
      {
        'question': l10n.faqSupportedLeagues,
        'answer': l10n.faqSupportedLeaguesAnswer,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          final isLast = index == faqs.length - 1;

          return _FAQItem(
            question: faq['question']!,
            answer: faq['answer']!,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _ContactItem(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF3B82F6),
            title: l10n.emailInquiry,
            subtitle: 'dudcks463@gmail.com',
            onTap: () => _launchEmail(context, subject: '[MatchLog]'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 56), color: _border),
          _ContactItem(
            icon: Icons.bug_report_outlined,
            iconColor: const Color(0xFFEF4444),
            title: l10n.bugReport,
            subtitle: l10n.bugReportDesc,
            onTap: () => _showBugReportDialog(context),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 56), color: _border),
          _ContactItem(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: l10n.featureSuggestion,
            subtitle: l10n.featureSuggestionDesc,
            onTap: () => _showFeatureRequestDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _InfoItem(
            title: l10n.appVersionLabel,
            value: _version.isEmpty ? '...' : 'v$_version',
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 16), color: _border),
          _InfoItem(
            title: l10n.buildNumber,
            value: _buildNumber.isEmpty ? '...' : _buildNumber,
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 16), color: _border),
          _InfoItem(
            title: l10n.developer,
            value: 'JO YEONG CHAN',
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _LinkItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF6B7280),
            title: l10n.privacyPolicy,
            onTap: () => _launchUrl('https://ychany.github.io/FootHub/privacy-policy.html'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 56), color: _border),
          _LinkItem(
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF6B7280),
            title: l10n.termsOfService,
            onTap: () => _launchUrl('https://ychany.github.io/FootHub/terms-of-service.html'),
          ),
          Container(height: 1, margin: const EdgeInsets.only(left: 56), color: _border),
          _LinkItem(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF6B7280),
            title: l10n.supportWebsite,
            onTap: () => _launchUrl('https://ychany.github.io/FootHub/'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(BuildContext context, {String? subject, String? body}) async {
    const email = 'dudcks463@gmail.com';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: _encodeQueryParameters({
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        Clipboard.setData(const ClipboardData(text: email));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.emailCopied}: $email')),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _showBugReportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => _FeedbackDialog(
        title: l10n.bugReport,
        hintText: l10n.bugReportHint,
        cancelText: l10n.cancel,
        submitText: l10n.submit,
        onSubmit: (text) {
          Navigator.pop(dialogContext);
          _launchEmail(
            context,
            subject: '[MatchLog Bug Report]',
            body: text,
          );
        },
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => _FeedbackDialog(
        title: l10n.featureSuggestion,
        hintText: l10n.featureSuggestionHint,
        cancelText: l10n.cancel,
        submitText: l10n.submit,
        onSubmit: (text) {
          Navigator.pop(dialogContext);
          _launchEmail(
            context,
            subject: '[MatchLog Feature Request]',
            body: text,
          );
        },
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool showDivider;

  const _FAQItem({
    required this.question,
    required this.answer,
    this.showDivider = true,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.answer,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (widget.showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 16),
            color: const Color(0xFFE5E7EB),
          ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _InfoItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _LinkItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.open_in_new, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String cancelText;
  final String submitText;
  final Function(String) onSubmit;

  const _FeedbackDialog({
    required this.title,
    required this.hintText,
    required this.cancelText,
    required this.submitText,
    required this.onSubmit,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelText, style: TextStyle(color: Colors.grey.shade600)),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSubmit(_controller.text);
            }
          },
          child: Text(widget.submitText, style: const TextStyle(color: Color(0xFF2563EB))),
        ),
      ],
    );
  }
}
