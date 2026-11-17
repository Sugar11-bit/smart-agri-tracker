import 'package:flutter/material.dart';

/// Login form. Session and network work are handled by the parent.
class LoginScreen extends StatelessWidget {
  final TextEditingController username;
  final TextEditingController password;
  final bool busy;
  final Future<void> Function() login;
  const LoginScreen({
    super.key,
    required this.username,
    required this.password,
    required this.busy,
    required this.login,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Farmer • Đăng nhập', style: TextStyle(fontSize: 24)),
          TextField(
            controller: username,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            autocorrect: false,
          ),
          TextField(
            controller: password,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            onSubmitted: (_) {
              if (!busy) login();
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : login,
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    ),
  );
}
