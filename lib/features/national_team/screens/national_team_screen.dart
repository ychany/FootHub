import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/api_football_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../providers/national_team_provider.dart';
import '../providers/selected_national_team_provider.dart';

class NationalTeamScreen extends ConsumerStatefulWidget {
  const NationalTeamScreen({super.key});

  @override
  ConsumerState<NationalTeamScreen> createState() => _NationalTeamScreenState();
}

class _NationalTeamScreenState extends ConsumerState<NationalTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  // 월드컵 트로피 테마 - 황금색 그라데이션
  static const _gradientStart = Color(0xFFE6B422);  // 밝은 골드

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countdown = ref.watch(worldCupCountdownProvider);
    final selectedTeam = ref.watch(selectedNationalTeamProvider);

    // 팀이 선택되지 않았으면 선택 안내 화면 표시
    if (selectedTeam == null) {
      return _buildNoTeamSelectedScreen(context, countdown);
    }

    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const BottomBannerAdWidget(),
      body: SafeArea(
        child: Column(
          children: [
            // 고정 헤더
            _buildHeader(context, selectedTeam, countdown),
            // 고정 탭바
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: _textSecondary,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.scheduleTab),
                  Tab(text: AppLocalizations.of(context)!.infoTab),
                  Tab(text: AppLocalizations.of(context)!.squadTab),
                ],
              ),
            ),
            // 스크롤되는 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ScheduleTab(),
                  _InfoTab(),
                  _SquadTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SelectedNationalTeam selectedTeam, WorldCupCountdown countdown) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _gradientStart,
            _gradientStart.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          // 상단 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'National Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // 팀 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 팀 엠블럼
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: selectedTeam.teamLogo != null
                        ? Image.network(
                            selectedTeam.teamLogo!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.flag,
                              size: 30,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.flag,
                            size: 30,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // 팀명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedTeam.teamName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'National Team',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 월드컵 카운트다운 배너
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countdown.tournamentName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.untilOpening,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'D-${countdown.daysRemaining}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _gradientStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNoTeamSelectedScreen(BuildContext context, WorldCupCountdown countdown) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const BottomBannerAdWidget(),
      appBar: AppBar(
        backgroundColor: _gradientStart,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.nationalTeam,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // 월드컵 카운트다운 배너
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countdown.tournamentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.untilOpening,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'D-${countdown.daysRemaining}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _gradientStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 팀 선택 안내
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.selectNationalTeam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectNationalTeam,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/national-team/select'),
                    icon: const Icon(Icons.search),
                    label: Text(l10n.selectCountryButton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gradientStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 일정 탭
// ============================================================================
class _ScheduleTab extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(selectedTeamAllMatchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 48, color: _textSecondary),
                const SizedBox(height: 12),
                Text(
                  l10n.noSchedule,
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final upcomingMatches = matches.where((m) {
          return !m.dateKST.isBefore(todayStart);
        }).toList()
          ..sort((a, b) => a.dateKST.compareTo(b.dateKST));

        final pastMatches = matches.where((m) {
          return m.dateKST.isBefore(todayStart);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (upcomingMatches.isNotEmpty) ...[
              _buildSectionHeader(l10n.upcomingMatches, Icons.event_outlined, _primary, upcomingMatches.length),
              const SizedBox(height: 12),
              ...upcomingMatches.map((m) => _MatchCard(match: m, isPast: false)),
              const SizedBox(height: 24),
            ],
            if (pastMatches.isNotEmpty) ...[
              _buildSectionHeader(l10n.pastMatches, Icons.history, _textSecondary, pastMatches.length),
              const SizedBox(height: 12),
              ...pastMatches.map((m) => _MatchCard(match: m, isPast: true)),
            ],
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(
        child: Text('${l10n.errorPrefix}: $e', style: TextStyle(color: _textSecondary)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final ApiFootballFixture match;
  final bool isPast;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _primary = Color(0xFF2563EB);

  const _MatchCard({required this.match, required this.isPast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTeam = ref.watch(selectedNationalTeamProvider);
    final matchDate = match.dateKST;
    final isMyTeamHome = match.homeTeam.id == selectedTeam?.teamId;

    return GestureDetector(
      onTap: () => context.push('/match/${match.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            // 리그 & 날짜
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.league.name,
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat(AppLocalizations.of(context)!.dateFormatDiary, Localizations.localeOf(context).toString()).format(matchDate),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 팀 vs 팀
            Row(
              children: [
                // 홈팀
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        match.homeTeam.logo,
                        isMyTeam: isMyTeamHome,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.homeTeam.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isMyTeamHome ? _primary : _textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 스코어 or 시간
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      if (isPast && match.homeGoals != null && match.awayGoals != null)
                        Text(
                          '${match.homeGoals} - ${match.awayGoals}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        )
                      else
                        Text(
                          DateFormat('HH:mm').format(matchDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      if (match.venue != null && match.venue!.name != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          match.venue!.name!,
                          style: TextStyle(
                            fontSize: 10,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 원정팀
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        match.awayTeam.logo,
                        isMyTeam: !isMyTeamHome,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.awayTeam.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !isMyTeamHome ? _primary : _textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String? badgeUrl, {bool isMyTeam = false}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isMyTeam ? _primary.withValues(alpha: 0.3) : _border,
          width: isMyTeam ? 2 : 1,
        ),
        color: Colors.white,
      ),
      child: ClipOval(
        child: badgeUrl != null
            ? CachedNetworkImage(
                imageUrl: badgeUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade100),
                errorWidget: (_, __, ___) => Icon(
                  Icons.shield_outlined,
                  color: _textSecondary,
                  size: 24,
                ),
              )
            : Icon(
                Icons.shield_outlined,
                color: _textSecondary,
                size: 24,
              ),
      ),
    );
  }
}

// ============================================================================
// 정보 탭
// ============================================================================
class _InfoTab extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final teamAsync = ref.watch(selectedTeamInfoProvider);
    final formAsync = ref.watch(selectedTeamFormProvider);

    return teamAsync.when(
      data: (team) {
        if (team == null) {
          return Center(child: Text(l10n.cannotLoadTeamInfo));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 기본 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.basicInfoSection,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.flag_outlined, label: l10n.countryLabel, value: team.country ?? '-'),
                  _InfoRow(icon: Icons.stadium_outlined, label: l10n.homeStadiumLabel, value: team.venue?.name ?? '-'),
                  if (team.venue?.capacity != null)
                    _InfoRow(icon: Icons.people_outline, label: l10n.capacityLabel, value: l10n.capacityValue(team.venue!.capacity!)),
                  if (team.founded != null)
                    _InfoRow(icon: Icons.calendar_today_outlined, label: l10n.foundedLabel, value: team.founded.toString()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 최근 폼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.last5Form,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  formAsync.when(
                    data: (form) {
                      if (form == null) {
                        return Text(l10n.noFormInfo);
                      }
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: form.results.map((r) {
                              Color bgColor;
                              switch (r) {
                                case 'W':
                                  bgColor = const Color(0xFF10B981);
                                  break;
                                case 'L':
                                  bgColor = const Color(0xFFEF4444);
                                  break;
                                default:
                                  bgColor = const Color(0xFF6B7280);
                              }
                              return Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(label: l10n.winShort, value: '${form.wins}', color: const Color(0xFF10B981)),
                              _StatItem(label: l10n.drawShort, value: '${form.draws}', color: const Color(0xFF6B7280)),
                              _StatItem(label: l10n.loseShort, value: '${form.losses}', color: const Color(0xFFEF4444)),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text(l10n.cannotLoadFormInfo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 참가 대회 (동적)
            _DynamicCompetitionsCard(),
          ],
        );
      },
      loading: () => const LoadingIndicator(),
      error: (e, _) => Center(child: Text('${l10n.errorPrefix}: $e')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

/// 동적 참가 대회 카드
class _DynamicCompetitionsCard extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final competitionsAsync = ref.watch(selectedTeamCompetitionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.competitionsSection,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.tapForLeagueDetail,
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          competitionsAsync.when(
            data: (competitions) {
              if (competitions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      l10n.noCompetitionInfo,
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                children: competitions.map((league) => _DynamicCompetitionItem(league: league)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.cannotLoadCompetitionInfo,
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 동적 대회 항목
class _DynamicCompetitionItem extends StatelessWidget {
  final ApiFootballTeamLeague league;

  static const _textSecondary = Color(0xFF6B7280);

  const _DynamicCompetitionItem({required this.league});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/league/${league.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            if (league.logo != null)
              CachedNetworkImage(
                imageUrl: league.logo!,
                width: 24,
                height: 24,
                errorWidget: (_, __, ___) => const Icon(Icons.emoji_events, size: 20),
              )
            else
              const Icon(Icons.emoji_events, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                league.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// 선수단 탭
// ============================================================================
class _SquadTab extends ConsumerWidget {
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final squadAsync = ref.watch(selectedTeamSquadProvider);

    return squadAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.noSquadInfo,
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 포지션별 그룹화
        final goalkeepers = players.where((p) => p.position?.toLowerCase() == 'goalkeeper').toList();
        final defenders = players.where((p) => p.position?.toLowerCase() == 'defender').toList();
        final midfielders = players.where((p) => p.position?.toLowerCase() == 'midfielder').toList();
        final attackers = players.where((p) => p.position?.toLowerCase() == 'attacker').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (goalkeepers.isNotEmpty) ...[
              _buildSectionCard(l10n.goalkeepersSection, goalkeepers),
              const SizedBox(height: 16),
            ],
            if (defenders.isNotEmpty) ...[
              _buildSectionCard(l10n.defendersSection, defenders),
              const SizedBox(height: 16),
            ],
            if (midfielders.isNotEmpty) ...[
              _buildSectionCard(l10n.midfieldersSection, midfielders),
              const SizedBox(height: 16),
            ],
            if (attackers.isNotEmpty) ...[
              _buildSectionCard(l10n.attackersSection, attackers),
            ],
            if (goalkeepers.isEmpty && defenders.isEmpty && midfielders.isEmpty && attackers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 32, color: _textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        l10n.squadInfoNote,
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _textSecondary),
            const SizedBox(height: 12),
            Text('${l10n.errorPrefix}: $e', style: TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<ApiFootballSquadPlayer> players) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...players.map((player) => _PlayerRow(player: player)),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final ApiFootballSquadPlayer player;

  const _PlayerRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/player/${player.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
              ),
              child: player.photo != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: player.photo!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person, color: Color(0xFF6B7280)),
                      ),
                    )
                  : const Icon(Icons.person, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (player.number != null)
                    Text(
                      '#${player.number}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
