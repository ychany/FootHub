import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_settings_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/error_helper.dart';
import '../../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFDBEAFE);
  static const _textPrimary = Color(0xFF111827);
  static const _background = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _requestPermissionIfNeeded();
  }

  Future<void> _requestPermissionIfNeeded() async {
    // iOS에서는 먼저 권한을 요청해야 설정에 앱이 나타남
    if (Platform.isIOS) {
      await LocalNotificationService().requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
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
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.notificationSettings,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: settingsAsync.when(
          data: (settings) => _buildContent(settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(ErrorHelper.getLocalizedErrorMessage(context, e))),
        ),
      ),
    );
  }

  Widget _buildContent(NotificationSettings settings) {
    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 푸시 알림 마스터 스위치
          _buildSectionHeader(
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFFEC4899),
            title: l10n.pushNotifications,
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: l10n.receivePushNotifications,
                subtitle: l10n.masterSwitch,
                value: settings.pushNotifications,
                onChanged: (value) => notifier.updatePushNotifications(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 즐겨찾기 팀 경기 알림
          _buildSectionHeader(
            icon: Icons.sports_soccer_rounded,
            iconColor: const Color(0xFF10B981),
            title: l10n.favoriteTeamMatchNotifications,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.favoriteTeamMatchNotificationsDesc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: l10n.matchStartNotification,
                subtitle: l10n.matchStartNotificationDesc,
                value: settings.matchReminder,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateMatchReminder(value),
              ),
              const _Divider(),
              _SettingsDropdown(
                title: l10n.notificationTime,
                subtitle: l10n.notificationTimeDesc,
                value: settings.matchReminderMinutes,
                enabled: settings.pushNotifications && settings.matchReminder,
                options: const [15, 30, 60, 120],
                optionLabels: [l10n.minutes15Before, l10n.minutes30Before, l10n.hour1Before, l10n.hours2Before],
                onChanged: (value) => notifier.updateMatchReminderMinutes(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 즐겨찾기 팀 실시간 알림
          _buildSectionHeader(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: l10n.favoriteTeamLiveNotifications,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.favoriteTeamLiveNotificationsDesc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: l10n.liveScoreUpdates,
                subtitle: l10n.liveScoreUpdatesDesc,
                value: settings.liveScoreUpdates,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateLiveScoreUpdates(value),
              ),
              const _Divider(),
              _SettingsToggle(
                title: l10n.lineupNotifications,
                subtitle: l10n.lineupNotificationsDesc,
                value: settings.notifyLineup,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateNotifyLineup(value),
              ),
              const _Divider(),
              _SettingsToggle(
                title: l10n.resultNotifications,
                subtitle: l10n.resultNotificationsDesc,
                value: settings.notifyResult,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateNotifyResult(value),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 즐겨찾기 선수 실시간 알림
          _buildSectionHeader(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: l10n.favoritePlayerLiveNotifications,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.favoritePlayerLiveNotificationsDesc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsToggle(
                title: l10n.favoritePlayerEvents,
                subtitle: l10n.favoritePlayerEventsDesc,
                value: settings.favoritePlayerEvents,
                enabled: settings.pushNotifications,
                onChanged: (value) => notifier.updateFavoritePlayerEvents(value),
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
                        l10n.notificationPermissionGuide,
                        style: TextStyle(
                          color: _primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.notificationPermissionDesc,
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
              activeThumbColor: const Color(0xFF2563EB),
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
