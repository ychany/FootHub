import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';

/// AppException을 로컬라이즈된 메시지로 변환하는 헬퍼
class ErrorHelper {
  /// AppException 에러 코드를 로컬라이즈된 메시지로 변환
  static String getLocalizedErrorMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context)!;

    // 1. AppException 처리
    if (error is AppException) {
      return _getMessageForCode(l10n, error.code);
    }

    // 2. 네트워크 에러
    if (error is SocketException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable')) {
      return l10n.errorNetwork;
    }

    // 3. 타임아웃
    if (error is TimeoutException ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('timed out')) {
      return l10n.errorTimeout;
    }

    // 4. Firebase 에러
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(l10n, error);
    }

    // 5. HTTP 서버 에러 (5xx)
    if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('Internal Server Error')) {
      return l10n.errorServer;
    }

    // 6. 기존 Exception 문자열에서 에러 코드 추출 시도
    final errorString = error.toString();
    for (final code in AppErrorCode.values) {
      if (errorString.contains(code.name)) {
        return _getMessageForCode(l10n, code);
      }
    }

    return l10n.errorUnknown;
  }

  /// Firebase 에러를 로컬라이즈된 메시지로 변환
  static String _getFirebaseErrorMessage(
      AppLocalizations l10n, FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return l10n.errorFirebasePermission;
      case 'not-found':
        return l10n.errorFirebaseNotFound;
      case 'unavailable':
        return l10n.errorFirebaseUnavailable;
      default:
        return l10n.errorUnknown;
    }
  }

  static String _getMessageForCode(AppLocalizations l10n, AppErrorCode code) {
    switch (code) {
      case AppErrorCode.loginRequired:
        return l10n.errorLoginRequired;
      case AppErrorCode.postNotFound:
        return l10n.errorPostNotFound;
      case AppErrorCode.postEditPermissionDenied:
        return l10n.errorPostEditPermissionDenied;
      case AppErrorCode.postDeletePermissionDenied:
        return l10n.errorPostDeletePermissionDenied;
      case AppErrorCode.commentNotFound:
        return l10n.errorCommentNotFound;
      case AppErrorCode.commentDeletePermissionDenied:
        return l10n.errorCommentDeletePermissionDenied;
      case AppErrorCode.networkError:
        return l10n.errorNetworkError;
      case AppErrorCode.unknownError:
        return l10n.errorUnknown;
    }
  }

  /// 부상/상태 타입을 로컬라이즈된 문자열로 변환
  static String getLocalizedInjuryType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    final typeLower = type.toLowerCase();

    // 부상 종류
    if (typeLower.contains('knee')) return l10n.injuryKnee;
    if (typeLower.contains('hamstring')) return l10n.injuryHamstring;
    if (typeLower.contains('muscle')) return l10n.injuryMuscle;
    if (typeLower.contains('ankle')) return l10n.injuryAnkle;
    if (typeLower.contains('groin')) return l10n.injuryGroin;
    if (typeLower.contains('back')) return l10n.injuryBack;
    if (typeLower.contains('shoulder')) return l10n.injuryShoulder;
    if (typeLower.contains('achilles')) return l10n.injuryAchilles;
    if (typeLower.contains('calf')) return l10n.injuryCalf;
    if (typeLower.contains('thigh')) return l10n.injuryThigh;
    if (typeLower.contains('hip')) return l10n.injuryHip;
    if (typeLower.contains('broken') || typeLower.contains('fracture')) {
      return l10n.injuryFracture;
    }
    if (typeLower.contains('concussion')) return l10n.injuryConcussion;
    if (typeLower.contains('ligament') ||
        typeLower.contains('acl') ||
        typeLower.contains('mcl')) {
      return l10n.injuryLigament;
    }
    if (typeLower.contains('surgery')) return l10n.injurySurgery;
    if (typeLower.contains('illness')) return l10n.injuryIllness;
    if (typeLower.contains('injury')) return l10n.injuryGeneral;

    // 징계/출전정지
    if (typeLower.contains('suspension') || typeLower.contains('suspended')) {
      return l10n.statusSuspension;
    }
    if (typeLower.contains('red card')) return l10n.statusRedCard;
    if (typeLower.contains('yellow card')) return l10n.statusYellowCard;
    if (typeLower.contains('ban')) return l10n.statusBan;
    if (typeLower.contains('disciplinary')) return l10n.statusDisciplinary;

    // 기타 사유
    if (typeLower.contains('missing')) return l10n.statusMissing;
    if (typeLower.contains('personal')) return l10n.statusPersonal;
    if (typeLower.contains('international')) return l10n.statusInternational;
    if (typeLower.contains('rest')) return l10n.statusRest;
    if (typeLower.contains('fitness')) return l10n.statusFitness;

    return type; // 매칭되지 않으면 원본 반환
  }

  /// 선수 상태를 로컬라이즈된 문자열로 변환
  static String getLocalizedPlayerStatus(
    BuildContext context, {
    required bool isSuspended,
    required bool isInjury,
    required bool isDoubtful,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (isSuspended) return l10n.statusSuspended;
    if (isInjury) return l10n.statusInjury;
    if (isDoubtful) return l10n.statusDoubtful;
    return l10n.statusAbsent;
  }

  /// 배팅 타입을 로컬라이즈된 문자열로 변환
  static String getLocalizedBetType(BuildContext context, String betName) {
    final l10n = AppLocalizations.of(context)!;
    final nameLower = betName.toLowerCase();

    if (nameLower.contains('match winner') || nameLower == 'home/away') {
      return l10n.betMatchWinner;
    }
    if (nameLower.contains('asian handicap') ||
        nameLower.contains('handicap')) {
      return l10n.betHandicap;
    }
    if (nameLower.contains('goals over/under') ||
        nameLower == 'over/under' ||
        nameLower.contains('total goals')) {
      return l10n.betOverUnder;
    }
    if (nameLower.contains('first half over/under') ||
        nameLower.contains('1st half over')) {
      return l10n.betFirstHalfOU;
    }
    if (nameLower.contains('second half over/under') ||
        nameLower.contains('2nd half over')) {
      return l10n.betSecondHalfOU;
    }
    if (nameLower.contains('half time / full time') ||
        nameLower.contains('ht/ft')) {
      return l10n.betHalfFullTime;
    }
    if (nameLower.contains('both teams score') ||
        nameLower.contains('both teams to score')) {
      return l10n.betBothTeamsScore;
    }
    if (nameLower.contains('exact score') ||
        nameLower.contains('correct score')) {
      return l10n.betExactScore;
    }
    if (nameLower.contains('double chance')) {
      return l10n.betDoubleChance;
    }
    if (nameLower.contains('first half winner') ||
        nameLower.contains('1st half result')) {
      return l10n.betFirstHalfWinner;
    }
    if (nameLower.contains('second half winner') ||
        nameLower.contains('2nd half result')) {
      return l10n.betSecondHalfWinner;
    }
    if (nameLower.contains('odd/even') || nameLower.contains('odd or even')) {
      return l10n.betOddEven;
    }
    if (nameLower.contains('home team goals') ||
        nameLower.contains('home total')) {
      return l10n.betHomeTeamGoals;
    }
    if (nameLower.contains('away team goals') ||
        nameLower.contains('away total')) {
      return l10n.betAwayTeamGoals;
    }
    if (nameLower.contains('draw no bet')) {
      return l10n.betDrawNoBet;
    }
    if (nameLower.contains('result/both teams')) {
      return l10n.betResultBothScore;
    }
    if (nameLower.contains('first half exact') ||
        nameLower.contains('1st half correct')) {
      return l10n.betFirstHalfExact;
    }
    if (nameLower.contains('winning margin') ||
        nameLower.contains('goals difference')) {
      return l10n.betGoalsDifference;
    }

    return betName; // 매칭되지 않으면 원본 반환
  }

  /// 익명 사용자 이름 가져오기
  static String getAnonymousName(BuildContext context) {
    return AppLocalizations.of(context)!.anonymous;
  }

  /// 기간 표시 텍스트를 로컬라이즈된 문자열로 변환
  static String getLocalizedPeriodText(BuildContext context, String period) {
    final l10n = AppLocalizations.of(context)!;
    final periodLower = period.toLowerCase();

    if (periodLower == 'ongoing') return l10n.periodOngoing;
    if (periodLower == 'current') return l10n.periodCurrent;

    return period; // 매칭되지 않으면 원본 반환
  }
}
