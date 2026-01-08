import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

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
        bottomNavigationBar: const BottomBannerAdWidget(),
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
          Container(height: 1, margin: const EdgeInsets.only(left: 16), color: _border),
          _LinkItem(
            icon: Icons.new_releases_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: l10n.patchNotes,
            onTap: () => _showPatchNotes(context),
          ),
        ],
      ),
    );
  }

  void _showPatchNotes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PatchNotesScreen(),
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

// ============================================================================
// 패치노트 화면
// ============================================================================
class PatchNotesScreen extends StatelessWidget {
  const PatchNotesScreen({super.key});

  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: _textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.patchNotes,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _PatchNoteCard(
            version: '1.1.0',
            buildNumber: '1',
            isLatest: true,
            items: [
              '즐겨찾기 팀 알림 기능',
              'A매치에 필터 추가, 달력 수정',
              '팀정보 순위페이지 추가',
              '팀정보 이적탭 날짜 파싱 수정',
              '선수정보 출전경기 탭 추가',
              '라인업 페이지 교체 아웃 추가',
              '부상/결장 선수 디테일 페이지 오류 수정',
              '팀정보 - 일정탭 날짜 기준 수정',
              '라이브 데이터 자동 갱신 개선',
            ],
          ),
          SizedBox(height: 16),
          _PatchNoteCard(
            version: '1.0.0',
            buildNumber: '3',
            items: [
              '리그 일정에 라운드 표시',
              '하프타임(HT) 표시',
              '시즌 자동 감지 개선',
              '자국 리그 필터 자동 추가',
              '즐겨찾기 선수 검색 개선',
            ],
          ),
          SizedBox(height: 16),
          _PatchNoteCard(
            version: '1.0.0',
            buildNumber: '2',
            items: [
              'Apple 로그인 지원',
              '회원탈퇴 기능 추가',
              '커뮤니티 신고/차단 기능',
              '국가별 리그 탐색 페이지',
              '라이브 경기 추가시간 표시',
              '성능 개선 및 버그 수정',
            ],
          ),
        ],
      ),
    );
  }
}

class _PatchNoteCard extends StatelessWidget {
  final String version;
  final String buildNumber;
  final bool isLatest;
  final List<String> items;

  const _PatchNoteCard({
    required this.version,
    required this.buildNumber,
    this.isLatest = false,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          width: isLatest ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLatest
                  ? const Color(0xFF2563EB).withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLatest
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'v$version+$buildNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Latest',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•  ',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
