import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

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
          title: const Text(
            '알림 설정',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: settingsAsync.when(
          data: (settings) => _buildContent(context, ref, settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류 발생: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, NotificationSettings settings) {
    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 푸시 알림 마스터 스위치
          _buildSectionHeader(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFEC4899),
            title: '푸시 알림',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: '푸시 알림 받기',
                subtitle: '모든 알림의 마스터 스위치',
                value: settings.pushNotifications,
                onChanged: (value) => notifier.updatePushNotifications(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 경기 알림
          _buildSectionHeader(
            icon: Icons.sports_soccer_rounded,
            iconColor: const Color(0xFF10B981),
            title: '경기 알림',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: '경기 시작 알림',
                subtitle: '경기 시작 전 미리 알림 받기',
                value: settings.matchReminder,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateMatchReminder(value),
              ),
              const _Divider(),
              _SettingsDropdown(
                title: '알림 시간',
                subtitle: '경기 시작 전 알림 시간',
                value: settings.matchReminderMinutes,
                enabled: settings.pushNotifications && settings.matchReminder,
                options: const [15, 30, 60, 120],
                optionLabels: const ['15분 전', '30분 전', '1시간 전', '2시간 전'],
                onChanged: (value) => notifier.updateMatchReminderMinutes(value),
              ),
              const _Divider(),
              _SettingsToggle(
                title: '즐겨찾기 팀 경기',
                subtitle: '즐겨찾기한 팀 경기 일정 알림',
                value: settings.favoriteTeamMatches,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateFavoriteTeamMatches(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 실시간 알림
          _buildSectionHeader(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: '실시간 알림',
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: '라이브 스코어 업데이트',
                subtitle: '즐겨찾기 팀 경기 중 골/이벤트 알림',
                value: settings.liveScoreUpdates,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateLiveScoreUpdates(value),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '알림 권한 안내',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '알림을 받으려면 기기 설정에서 MatchLog 앱의 알림 권한을 허용해주세요.',
                        style: TextStyle(
                          color: _primary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
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
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
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
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final bool enabled;
  final List<int> options;
  final List<String> optionLabels;
  final ValueChanged<int> onChanged;

  const _SettingsDropdown({
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.options,
    required this.optionLabels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: value,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(Icons.expand_more, color: Colors.grey.shade600, size: 18),
                items: List.generate(options.length, (index) {
                  return DropdownMenuItem(
                    value: options[index],
                    child: Text(
                      optionLabels[index],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                onChanged: enabled ? (v) => onChanged(v!) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 16),
      color: const Color(0xFFE5E7EB),
    );
  }
}
