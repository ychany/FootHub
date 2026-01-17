import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
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
            icon: const Icon(Icons.arrow_back_ios, color: _textPrimary, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            l10n.languageSettings,
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
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  // 시스템 기본
                  _LanguageOption(
                    title: l10n.systemDefault,
                    subtitle: _getSystemLanguageDescription(context),
                    isSelected: currentLocale == null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(null);
                    },
                  ),
                  Divider(height: 1, color: _border, indent: 60, endIndent: 16),
                  // 한국어
                  _LanguageOption(
                    title: l10n.korean,
                    subtitle: 'Korean',
                    isSelected: currentLocale?.languageCode == 'ko',
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(const Locale('ko'));
                    },
                  ),
                  Divider(height: 1, color: _border, indent: 60, endIndent: 16),
                  // 영어
                  _LanguageOption(
                    title: l10n.english,
                    subtitle: 'English',
                    isSelected: currentLocale?.languageCode == 'en',
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _getLanguageNote(context),
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSystemLanguageDescription(BuildContext context) {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final l10n = AppLocalizations.of(context)!;
    String languageName;
    switch (systemLocale.languageCode) {
      case 'ko':
        languageName = l10n.korean;
        break;
      case 'en':
        languageName = l10n.english;
        break;
      default:
        languageName = systemLocale.languageCode;
    }
    return l10n.currentLanguage(languageName);
  }

  String _getLanguageNote(BuildContext context) {
    return AppLocalizations.of(context)!.languageChangeNote;
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.language,
                color: isSelected ? _primary : _textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
