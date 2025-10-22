import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final Permission? requiredPermission;
  final UserRole? requiredRole;
  final Widget? fallback;

  const ProtectedRoute({
    Key? key,
    required this.child,
    this.requiredPermission,
    this.requiredRole,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return fallback ?? _UnauthorizedWidget(
            message: 'Bạn cần đăng nhập để truy cập',
          );
        }

        if (requiredRole != null && !authProvider.hasRole(requiredRole!)) {
          return fallback ?? _UnauthorizedWidget(
            message: 'Vai trò của bạn không được phép truy cập',
          );
        }

        return child;
      },
    );
  }
}

class _UnauthorizedWidget extends StatelessWidget {
  final String message;

  const _UnauthorizedWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: Colors.red[600],
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Không có quyền truy cập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield,
                        color: Colors.amber[700],
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Liên hệ quản trị viên nếu bạn cần được cấp quyền truy cập.',
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}