/// 앱 전체에서 사용하는 에러 코드
enum AppErrorCode {
  // 인증 관련
  loginRequired,

  // 게시글 관련
  postNotFound,
  postEditPermissionDenied,
  postDeletePermissionDenied,

  // 댓글 관련
  commentNotFound,
  commentDeletePermissionDenied,

  // 네트워크 관련
  networkError,

  // 일반
  unknownError,
}

/// 서비스 레이어에서 사용하는 커스텀 예외
class AppException implements Exception {
  final AppErrorCode code;
  final String? debugMessage;

  const AppException(this.code, {this.debugMessage});

  @override
  String toString() {
    // 디버그용 메시지 (로그에만 사용)
    return debugMessage ?? code.name;
  }
}
