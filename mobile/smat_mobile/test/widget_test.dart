import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smat_mobile/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('Login form replaces counter demo and validates empty input', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Farmer • Đăng nhập'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(find.text('Nhập tên đăng nhập và mật khẩu.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
