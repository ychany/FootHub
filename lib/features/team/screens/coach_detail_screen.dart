import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_football_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/banner_ad_widget.dart';

// Coach detail provider
final coachDetailProvider = FutureProvider.family<ApiFootballCoach?, int>((ref, coachId) async {
  final service = ApiFootballService();
  return service.getCoachById(coachId);
});

// Coach trophies provider
final coachTrophiesProvider = FutureProvider.family<List<CoachTrophy>, int>((ref, coachId) async {
  final service = ApiFootballService();
  return service.getCoachTrophies(coachId);
});

// Coach sidelined provider (출전정지 이력)
final coachSidelinedProvider = FutureProvider.family<List<ApiFootballSidelined>, int>((ref, coachId) async {
  final service = ApiFootballService();
  return service.getCoachSidelined(coachId);
});

class CoachDetailScreen extends ConsumerWidget {
  final String coachId;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);

  const CoachDetailScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(coachId);
    if (id == null) {
      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Center(
                  child: Text(AppLocalizations.of(context)!.invalidCoachId),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final coachAsync = ref.watch(coachDetailProvider(id));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _background,
        bottomNavigationBar: const BottomBannerAdWidget(),
        body: coachAsync.when(
          data: (coach) {
            if (coach == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline,
                                size: 64, color: _textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noPlayerInfo,
                              style: TextStyle(color: _textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _CoachDetailContent(coach: coach);
          },
          loading: () => const LoadingIndicator(),
          error: (e, _) => SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Center(
                    child: Text('${AppLocalizations.of(context)!.error}: $e', style: TextStyle(color: _textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: _textPrimary,
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Builder(
              builder: (context) => Text(
                AppLocalizations.of(context)!.manager,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CoachDetailContent extends ConsumerWidget {
  final ApiFootballCoach coach;

  static const _primary = Color(0xFF2563EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _gold = Color(0xFFFFD700);

  const _CoachDetailContent({required this.coach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(coachTrophiesProvider(coach.id));
    final sidelinedAsync = ref.watch(coachSidelinedProvider(coach.id));

    return SafeArea(
      child: Column(
        children: [
          // 헤더
          _buildHeader(context),

          // 내용
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 기본 정보 카드
                _buildBasicInfoCard(context),

                const SizedBox(height: 16),

                // 출전정지 이력 카드
                _CoachSidelinedSection(sidelinedAsync: sidelinedAsync),

                // 트로피 카드
                trophiesAsync.when(
                  data: (trophies) {
                    if (trophies.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        _buildTrophiesCard(context, trophies),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      _buildTrophiesLoadingCard(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // 경력 카드
                if (coach.career.isNotEmpty) _buildCareerCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 앱바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: _textPrimary,
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.coachInfo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 프로필 이미지
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: coach.photo != null
                  ? CachedNetworkImage(
                      imageUrl: coach.photo!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: _textSecondary,
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // 이름
          Text(
            coach.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          // 국적
          if (coach.nationality != null) ...[
            const SizedBox(height: 4),
            Text(
              coach.nationality!,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.basicInfo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (coach.age != null)
            _InfoRow(
              icon: Icons.cake_outlined,
              label: l10n.ageLabel,
              value: l10n.ageYearsValue(coach.age!),
            ),
          if (coach.birthDate != null)
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: l10n.birthDateLabel,
              value: coach.birthDate!,
            ),
          if (coach.birthPlace != null)
            _InfoRow(
              icon: Icons.location_city_outlined,
              label: l10n.birthPlaceLabel,
              value: coach.birthPlace!,
            ),
          if (coach.birthCountry != null)
            _InfoRow(
              icon: Icons.flag_outlined,
              label: l10n.birthCountry,
              value: coach.birthCountry!,
            ),
          if (coach.totalCareerYears > 0)
            _InfoRow(
              icon: Icons.work_outline,
              label: l10n.coachCareer,
              value: l10n.careerYears(coach.totalCareerYears),
            ),
        ],
      ),
    );
  }

  Widget _buildTrophiesLoadingCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events, color: _gold, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.trophyRecord,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophiesCard(BuildContext context, List<CoachTrophy> trophies) {
    final l10n = AppLocalizations.of(context)!;
    // 우승만 필터링하고 시즌 기준 정렬
    final winners = trophies.where((t) => t.isWinner).toList()
      ..sort((a, b) => b.season.compareTo(a.season));

    // 준우승 필터링
    final runnerUps = trophies.where((t) => t.isRunnerUp).toList()
      ..sort((a, b) => b.season.compareTo(a.season));

    final winnerCount = winners.length;
    final runnerUpCount = runnerUps.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.emoji_events, color: _gold, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.trophyRecord,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                // 우승/준우승 카운트
                if (winnerCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: _gold),
                        const SizedBox(width: 4),
                        Text(
                          '$winnerCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (runnerUpCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '$runnerUpCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // 우승 목록
          if (winners.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.championTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
            ...winners.take(10).map((trophy) => _TrophyTile(
              trophy: trophy,
              isWinner: true,
            )),
            if (winners.length > 10)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.andNMore(winners.length - 10),
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ),
          ],

          // 준우승 목록
          if (runnerUps.isNotEmpty) ...[
            if (winners.isNotEmpty) const Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                l10n.runnerUpTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...runnerUps.take(5).map((trophy) => _TrophyTile(
              trophy: trophy,
              isWinner: false,
            )),
            if (runnerUps.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.andNMore(runnerUps.length - 5),
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCareerCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.history, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.careerTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.nTeams(coach.career.length),
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // 경력 목록
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coach.career.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
            itemBuilder: (context, index) {
              final career = coach.career[index];
              // 첫 번째 경력(가장 최근)이면서 end가 null인 경우에만 "현재"로 표시
              final isCurrentTeam = index == 0 && career.end == null;

              // end가 null이면 이전 경력(더 최근)의 start를 종료연도로 사용
              int? inferredEndYear = career.endYear;
              if (career.end == null && index > 0) {
                inferredEndYear = coach.career[index - 1].startYear;
              }

              return InkWell(
                onTap: career.teamId != null
                    ? () => context.push('/team/${career.teamId}')
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 팀 로고
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrentTeam ? _primary : _border,
                            width: isCurrentTeam ? 2 : 1,
                          ),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipOval(
                          child: career.teamLogo != null
                              ? CachedNetworkImage(
                                  imageUrl: career.teamLogo!,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => Icon(
                                    Icons.shield,
                                    size: 22,
                                    color: _textSecondary,
                                  ),
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.shield,
                                    size: 22,
                                    color: _textSecondary,
                                  ),
                                )
                              : Icon(
                                  Icons.shield,
                                  size: 22,
                                  color: _textSecondary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 팀 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    career.teamName ?? l10n.unknownTeam,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isCurrentTeam
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isCurrentTeam ? _primary : _textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentTeam) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      l10n.currentLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              // 첫 번째 경력만 "current" 표시, 나머지는 종료연도 표시
                              isCurrentTeam
                                  ? ErrorHelper.getLocalizedPeriodText(context, career.periodText)
                                  : '${career.startYear ?? '?'} - ${inferredEndYear ?? career.startYear ?? '?'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (career.teamId != null)
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _textSecondary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  final CoachTrophy trophy;
  final bool isWinner;

  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _gold = Color(0xFFFFD700);

  const _TrophyTile({
    required this.trophy,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // 트로피 아이콘
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isWinner
                  ? _gold.withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 16,
              color: isWinner ? _gold : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),

          // 대회 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trophy.league,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (trophy.country != null)
                  Text(
                    trophy.country!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // 시즌
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWinner
                  ? _gold.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trophy.season,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isWinner ? Colors.amber.shade800 : _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 출전정지 이력 섹션
class _CoachSidelinedSection extends StatelessWidget {
  final AsyncValue<List<ApiFootballSidelined>> sidelinedAsync;

  static const _error = Color(0xFFEF4444);
  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _CoachSidelinedSection({required this.sidelinedAsync});

  @override
  Widget build(BuildContext context) {
    return sidelinedAsync.when(
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();

        // 현재 진행 중인 출전정지
        final ongoingRecords = records.where((r) => r.isOngoing).toList();
        // 과거 기록 (최근 5개)
        final pastRecords = records.where((r) => !r.isOngoing).take(5).toList();

        return Column(
          children: [
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.gavel, color: _warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.suspensionHistory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.nCases(records.length),
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 현재 진행 중인 출전정지
                  if (ongoingRecords.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _error,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.currentlySuspended,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...ongoingRecords.map((record) => _CoachSidelinedItem(
                                record: record,
                                isOngoing: true,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 과거 기록
                  if (pastRecords.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.recentHistory,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pastRecords.map((record) => _CoachSidelinedItem(
                          record: record,
                          isOngoing: false,
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// 출전정지 개별 항목
class _CoachSidelinedItem extends StatelessWidget {
  final ApiFootballSidelined record;
  final bool isOngoing;

  static const _warning = Color(0xFFF59E0B);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _CoachSidelinedItem({
    required this.record,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOngoing ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gavel, color: _warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ErrorHelper.getLocalizedInjuryType(context, record.typeKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ErrorHelper.getLocalizedPeriodText(context, record.periodDisplay),
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppLocalizations.of(context)!.suspendedLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
