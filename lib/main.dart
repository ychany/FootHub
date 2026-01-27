import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/ad_service.dart';
import 'features/schedule/providers/schedule_provider.dart';
import 'app_router.dart';

void main() async {
  // 네이티브 스플래시 유지
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore 오프라인 퍼시스턴스 설정
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko', null);

  // 로컬 알림 서비스 초기화
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // 알림 탭 시 경기 상세 화면으로 이동
  notificationService.onNotificationTap = (payload) {
    if (payload != null && rootNavigatorKey.currentContext != null) {
      rootNavigatorKey.currentContext!.push('/match/$payload');
    }
  };

  // AdMob 초기화
  await AdService().initialize();

  // iOS ATT 권한 요청 (광고 추적 투명성)
  if (Platform.isIOS) {
    // 약간의 딜레이 후 ATT 요청 (앱 UI가 준비된 후)
    Future.delayed(const Duration(milliseconds: 500), () async {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    });
  }

  runApp(
    const ProviderScope(
      child: MatchLogApp(),
    ),
  );
}

class MatchLogApp extends ConsumerWidget {
  const MatchLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // 즐겨찾기 팀 경기 자동 알림 스케줄링 (백그라운드)
    ref.listen(autoScheduleFavoriteNotificationsProvider, (_, __) {});

    // 라이브 이벤트 모니터링 (즐겨찾기 팀/선수 골 알림)
    ref.watch(liveEventMonitorProvider);

    return MaterialApp.router(
      title: 'MatchLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // Localization 설정
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    );
  }
}
