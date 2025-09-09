import 'package:flutter/material.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AccessDenied extends StatelessWidget {
  final String? feature;
  final String? message;

  const AccessDenied({
    Key? key,
    this.feature,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final defaultMessage = feature != null
        ? 'Bạn không có quyền truy cập chức năng "$feature"'
        : 'Bạn không có quyền truy cập chức năng này';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 32,
                      color: Colors.orange.shade600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Không có quyền truy cập',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Message
                  Text(
                    message ?? defaultMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Current Role Info
                  if (user != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vai trò hiện tại:',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.roleDisplayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info Alert
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Liên hệ quản trị viên nếu bạn cần được cấp quyền truy cập chức năng này.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Quay lại'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}