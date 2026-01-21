import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_update_service.dart';
import '../../../features/national_team/providers/selected_national_team_provider.dart';
import '../../../features/favorites/providers/favorites_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/team_model.dart';
import '../../../shared/models/player_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // 네이티브 스플래시 제거
    FlutterNativeSplash.remove();

    // 초기화 및 네비게이션
    _initialize();
  }

  Future<void> _initialize() async {
    // 최소 1초 보장 + 실제 데이터 로딩 + 업데이트 체크 병렬 실행
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1000)),
      _loadInitialData(),
      AppUpdateService.isUpdateAvailable(),
    ]);

    if (!mounted) return;

    final isUpdateAvailable = results[2] as bool;

    // 업데이트 가능하면 다이얼로그 표시
    if (isUpdateAvailable) {
      final shouldUpdate = await _showUpdateDialog();
      if (shouldUpdate && mounted) {
        await launchUrl(
          Uri.parse(AppUpdateService.appStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }

    if (!mounted) return;

    // 홈으로 이동
    context.go('/home');
  }

  Future<bool> _showUpdateDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateAvailable),
        content: Text(l10n.updateAvailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.updateLater),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _loadInitialData() async {
    try {
      // SharedPreferences 초기화
      await SharedPreferences.getInstance();

      // 국가대표팀 선택 로드
      ref.read(selectedNationalTeamProvider);

      // 즐겨찾기 데이터 미리 로드
      await ref.read(favoriteTeamsProvider.future).catchError((_) => <Team>[]);
      await ref.read(favoritePlayersProvider.future).catchError((_) => <Player>[]);
    } catch (e) {
      // 초기화 실패해도 앱은 계속 진행
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 축구공 아이콘
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 앱 이름
                    Text(
                      'FootHub',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 슬로건
                    Text(
                      AppLocalizations.of(context)!.myFootballRecord,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // 로딩 인디케이터
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
