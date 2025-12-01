import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _storageService = StorageService();
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  String? _newPhotoUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final photoUrl = _newPhotoUrl ?? user?.photoURL;
    final displayName = user?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 24),
              // 프로필 이미지
              _buildProfileImage(photoUrl, displayName),
              const SizedBox(height: 12),
              // 사진 변경 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isUploadingPhoto ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('갤러리'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _isUploadingPhoto ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('카메라'),
                  ),
                  if (photoUrl != null || _selectedImage != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _isUploadingPhoto ? null : _removePhoto,
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),

              // 프로필 정보 카드
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('기본 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 이름 입력
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '이름',
                          hintText: '표시될 이름을 입력하세요',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 이메일 (수정 불가)
                      TextFormField(
                        initialValue: user?.email ?? '',
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: '이메일',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 계정 설정 카드
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
                      ),
                      title: const Text('비밀번호 변경'),
                      subtitle: Text('계정 보안을 위해 정기적으로 변경하세요', style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPasswordChangeDialog(),
                    ),
                    const Divider(height: 1, indent: 72),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                      title: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
                      subtitle: Text('모든 데이터가 삭제됩니다', style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () => _showDeleteAccountDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? photoUrl, String displayName) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (photoUrl != null ? NetworkImage(photoUrl) : null),
            child: _isUploadingPhoto
                ? const CircularProgressIndicator()
                : (_selectedImage == null && photoUrl == null)
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showPhotoOptions(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '프로필 사진 변경',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('갤러리에서 선택'),
              subtitle: const Text('저장된 사진에서 선택합니다'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('카메라로 촬영'),
              subtitle: const Text('새로운 사진을 촬영합니다'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_selectedImage != null || _newPhotoUrl != null || ref.read(currentUserProvider)?.photoURL != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text('사진 삭제', style: TextStyle(color: Colors.red)),
                subtitle: const Text('프로필 사진을 제거합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isUploadingPhoto = true;
        });

        // Firebase Storage에 업로드
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          final url = await _storageService.uploadProfilePhoto(
            userId: userId,
            file: _selectedImage!,
          );

          setState(() {
            _newPhotoUrl = url;
            _isUploadingPhoto = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사진이 업로드되었습니다. 저장을 눌러 적용하세요.')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _newPhotoUrl = ''; // 빈 문자열로 설정하여 삭제 표시
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진이 삭제됩니다. 저장을 눌러 적용하세요.')),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        displayName: _nameController.text.trim(),
        photoUrl: _newPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 수정되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPasswordChangeDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('비밀번호 변경'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: '현재 비밀번호',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: '새 비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: '8자 이상 입력하세요',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: '새 비밀번호 확인',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호는 8자 이상이어야 합니다')),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호 변경 기능 준비 중')),
                );
              },
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('계정 삭제'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정말 계정을 삭제하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem('모든 직관 기록이 삭제됩니다'),
                  _buildWarningItem('즐겨찾기 정보가 삭제됩니다'),
                  _buildWarningItem('프로필 사진이 삭제됩니다'),
                  _buildWarningItem('이 작업은 되돌릴 수 없습니다'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계정 삭제 기능 준비 중')),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.remove, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
