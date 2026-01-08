import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timezone_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

class TimezoneSettingsScreen extends ConsumerStatefulWidget {
  const TimezoneSettingsScreen({super.key});

  @override
  ConsumerState<TimezoneSettingsScreen> createState() => _TimezoneSettingsScreenState();
}

class _TimezoneSettingsScreenState extends ConsumerState<TimezoneSettingsScreen> {
  String _searchQuery = '';

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF10B981);

  String _getTimezoneName(BuildContext context, String nameKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (nameKey) {
      case 'timezoneKoreaSeoul': return l10n.timezoneKoreaSeoul;
      case 'timezoneJapanTokyo': return l10n.timezoneJapanTokyo;
      case 'timezoneChinaShanghai': return l10n.timezoneChinaShanghai;
      case 'timezoneSingapore': return l10n.timezoneSingapore;
      case 'timezoneHongKong': return l10n.timezoneHongKong;
      case 'timezoneThailandBangkok': return l10n.timezoneThailandBangkok;
      case 'timezoneIndonesiaJakarta': return l10n.timezoneIndonesiaJakarta;
      case 'timezoneIndiaKolkata': return l10n.timezoneIndiaKolkata;
      case 'timezoneUAEDubai': return l10n.timezoneUAEDubai;
      case 'timezoneUKLondon': return l10n.timezoneUKLondon;
      case 'timezoneFranceParis': return l10n.timezoneFranceParis;
      case 'timezoneGermanyBerlin': return l10n.timezoneGermanyBerlin;
      case 'timezoneItalyRome': return l10n.timezoneItalyRome;
      case 'timezoneSpainMadrid': return l10n.timezoneSpainMadrid;
      case 'timezoneNetherlandsAmsterdam': return l10n.timezoneNetherlandsAmsterdam;
      case 'timezoneRussiaMoscow': return l10n.timezoneRussiaMoscow;
      case 'timezoneUSEastNewYork': return l10n.timezoneUSEastNewYork;
      case 'timezoneUSWestLA': return l10n.timezoneUSWestLA;
      case 'timezoneUSCentralChicago': return l10n.timezoneUSCentralChicago;
      case 'timezoneBrazilSaoPaulo': return l10n.timezoneBrazilSaoPaulo;
      case 'timezoneAustraliaSydney': return l10n.timezoneAustraliaSydney;
      case 'timezoneNewZealandAuckland': return l10n.timezoneNewZealandAuckland;
      default: return nameKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTimezone = ref.watch(timezoneProvider);

    // 검색 필터링
    final filteredTimezones = availableTimezones.where((tz) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final localizedName = _getTimezoneName(context, tz.nameKey);
      return localizedName.toLowerCase().contains(query) ||
          tz.id.toLowerCase().contains(query) ||
          tz.offset.toLowerCase().contains(query);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(context),

              // 검색 바
              _buildSearchBar(context),

              // 현재 설정
              _buildCurrentSetting(context, selectedTimezone),

              // 타임존 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filteredTimezones.length,
                  itemBuilder: (context, index) {
                    final tz = filteredTimezones[index];
                    final isSelected = tz.id == selectedTimezone;
                    return _TimezoneItem(
                      timezone: tz,
                      localizedName: _getTimezoneName(context, tz.nameKey),
                      isSelected: isSelected,
                      onTap: () => _selectTimezone(tz),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _textPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.timezoneSettingsTitle,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: l10n.searchTimezone,
          hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCurrentSetting(BuildContext context, String selectedTimezone) {
    final l10n = AppLocalizations.of(context)!;
    final current = availableTimezones.firstWhere(
      (tz) => tz.id == selectedTimezone,
      orElse: () => availableTimezones.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentSetting,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTimezoneName(context, current.nameKey),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              current.offset,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTimezone(TimezoneOption tz) async {
    await ref.read(timezoneProvider.notifier).setTimezone(tz.id);
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final localizedName = _getTimezoneName(context, tz.nameKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.timezoneChanged(localizedName)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

class _TimezoneItem extends StatelessWidget {
  final TimezoneOption timezone;
  final String localizedName;
  final bool isSelected;
  final VoidCallback onTap;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _success = Color(0xFF10B981);

  const _TimezoneItem({
    required this.timezone,
    required this.localizedName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _success.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _success : _border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _success.withValues(alpha: 0.15)
                    : _textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.public,
                color: isSelected ? _success : _textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedName,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timezone.id,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? _success.withValues(alpha: 0.15)
                    : _textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timezone.offset,
                style: TextStyle(
                  color: isSelected ? _success : _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_circle, color: _success, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
