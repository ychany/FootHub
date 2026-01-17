import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../attendance/models/attendance_record.dart';
import '../services/user_profile_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/error_helper.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _background = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);

  final UserProfileService _service = UserProfileService();

  UserProfile? _profile;
  List<AttendanceRecord> _records = [];
  AttendanceStats? _stats;
  int _postCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 표시할 이름 결정 (프로필 이름이 'Anonymous'가 아니면 사용, 아니면 URL에서 전달된 이름 사용)
  String _getDisplayName(BuildContext context) {
    final profileName = _profile?.displayName;
    final l10n = AppLocalizations.of(context)!;
    if (profileName != null && profileName != 'Anonymous' && profileName.isNotEmpty) {
      return profileName;
    }
    return widget.userName ?? l10n.profile;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getUserProfile(widget.userId),
        _service.getUserAttendanceRecords(widget.userId),
        _service.getUserPostCount(widget.userId),
      ]);

      final profile = results[0] as UserProfile?;
      final records = results[1] as List<AttendanceRecord>;
      final postCount = results[2] as int;

      // 통계 계산
      final stats = AttendanceStats.fromRecords(
        records,
        profile?.favoriteTeamId,
      );

      setState(() {
        _profile = profile;
        _records = records;
        _stats = stats;
        _postCount = postCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHelper.getLocalizedErrorMessage(context, e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => context.pop(),
          ),
          title: Text(
            _getDisplayName(context),
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(context)
                : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('${l10n.errorOccurred}\n$_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildStatsSection(),
            const SizedBox(height: 16),
            _buildRecentRecordsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: _border,
            backgroundImage: _profile?.photoUrl != null
                ? CachedNetworkImageProvider(_profile!.photoUrl!)
                : null,
            child: _profile?.photoUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),

          // 이름
          Text(
            _getDisplayName(context),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),

          // 소개글
          if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _profile!.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // 응원팀
          if (_profile?.favoriteTeamName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 14, color: _primary),
                  const SizedBox(width: 4),
                  Text(
                    _profile!.favoriteTeamName!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 게시글/직관 수
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCountItem(l10n.attendanceLabel, _stats?.totalMatches ?? 0),
                  Container(
                    width: 1,
                    height: 30,
                    color: _border,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  _buildCountItem(l10n.postsLabel, _postCount),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null || _stats!.totalMatches == 0) {
      return const SizedBox.shrink();
    }

    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.attendanceStats,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // 승/무/패
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.winShort,
                      _stats!.wins,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.drawShort,
                      _stats!.draws,
                      const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.lossShort,
                      _stats!.losses,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),

              // 승률
              if (_stats!.wins + _stats!.draws + _stats!.losses > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up, size: 18, color: _primary),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.winRate} ${_stats!.winRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 자주 가는 구장
              if (_stats!.stadiumVisits.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.frequentStadiums,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_stats!.stadiumVisits.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .take(5)
                      .map((entry) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.key} (${entry.value})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordsSection() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        if (_records.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Icon(Icons.sports_soccer, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  l10n.noAttendanceRecordsYet,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentMatchRecords,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      l10n.totalCount(_records.length),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length > 10 ? 10 : _records.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildRecordItem(_records[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordItem(AttendanceRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 날짜
          SizedBox(
            width: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.date.month}/${record.date.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  '${record.date.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 경기 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 리그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    record.league,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // 팀 vs 팀
                Text(
                  '${record.homeTeamName} ${record.scoreDisplay} ${record.awayTeamName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 구장
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: _textSecondary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        record.stadium,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
