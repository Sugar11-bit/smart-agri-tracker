import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/security/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/farmer_catalog/data/farmer_catalog_repository.dart';
import 'features/farmer_catalog/service/farmer_catalog_prefetch_service.dart';
import 'features/plots/data/plot_cache.dart';
import 'features/plots/data/plots_repository.dart';
import 'features/plots/presentation/my_plots_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Smart Agri-Tracker',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    ),
    home: const FarmerHome(),
  );
}

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});
  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> with WidgetsBindingObserver {
  final storage = TokenStorage();
  final api = ApiClient();
  final cache = PlotCache();
  final username = TextEditingController();
  final password = TextEditingController();

  Session? session;
  PlotsResult? result;
  String? error;
  bool busy = true;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    restore();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (session != null && !busy) refresh();
    });
  }

  Future<void> restore() async {
    try {
      session = await storage.read();
      if (session != null) {
        await refresh();
        return;
      }
    } catch (_) {
      error = 'Không thể đọc phiên đăng nhập an toàn. Hãy thử lại.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && session != null && !busy) {
      refresh();
    }
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Nhập tên đăng nhập và mật khẩu.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      result = null;
    });
    try {
      session = await AuthRepository(
        api,
        storage,
      ).login(username.text.trim(), password.text);
      password.clear();
      await refresh();
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e.status == 401
              ? 'Tên đăng nhập hoặc mật khẩu không đúng.'
              : e.status == 403
              ? 'Tài khoản chưa có quyền truy cập hoặc thành viên tổ chức đang bị khóa.'
              : 'Backend từ chối yêu cầu (${e.status}).';
        });
      }
    } on TimeoutException {
      showLoginError(
        'Backend phản hồi quá chậm. Kiểm tra Backend và kết nối Android.',
      );
    } on http.ClientException {
      showLoginError(
        'Không kết nối được Backend. Nếu dùng Android local, hãy chạy scripts/run-local.ps1 để thiết lập lại kết nối.',
      );
    } on FormatException {
      showLoginError('Backend trả dữ liệu không hợp lệ. Kiểm tra địa chỉ API.');
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Không hoàn tất đăng nhập. Kiểm tra dữ liệu API hoặc bộ nhớ an toàn trên thiết bị.';
        });
      }
    }
  }

  void showLoginError(String message) {
    if (!mounted) return;
    setState(() {
      busy = false;
      error = message;
    });
  }

  Future<void> refresh() async {
    final current = session;
    if (current == null) return;
    if (mounted) {
      setState(() {
        busy = true;
        error = null;
      });
    }
    try {
      final next = await PlotsRepository(api, cache).load(current);
      if (mounted) setState(() => result = next);
    } on ApiFailure catch (e) {
      result = null;
      if (e.status == 401 || e.status == 403) {
        result = null;
        session = null;
        try {
          await storage.clear();
        } catch (_) {
          error = 'Không thể xóa phiên đã hết hạn.';
        }
        error =
            'Phiên hết hạn hoặc quyền truy cập thay đổi. Hãy đăng nhập lại.';
      } else {
        error = 'Backend báo lỗi (${e.status}). Hãy thử lại.';
      }
    } catch (_) {
      error = 'Không thể đọc hoặc cập nhật dữ liệu khu đất.';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> prepareOfflineCatalog() async {
    final currentSession = session;
    final plots = result?.plots;
    if (busy || currentSession == null || plots == null) return;

    setState(() => busy = true);
    try {
      final summary = await FarmerCatalogPrefetchService(
        FarmerCatalogRepository(api, cache),
      ).prefetch(session: currentSession, plots: plots);
      if (!mounted || !identical(session, currentSession)) return;

      final counts =
          '${summary.plotsProcessed} khu đất, '
          '${summary.plantingsProcessed} đợt trồng, '
          '${summary.cyclesLoaded} kỳ sản xuất';
      final message = summary.hasErrors
          ? 'Tải chưa hoàn tất. Đã xử lý $counts. '
                '${summary.errors.length} yêu cầu thất bại.'
          : 'Đã tải từ Backend: $counts.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không hoàn tất tải dữ liệu offline.')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> logout() async {
    setState(() => busy = true);
    try {
      await storage.clear();
      session = null;
      result = null;
      error = null;
      password.clear();
    } catch (_) {
      error = 'Chưa thể xóa phiên an toàn. Hãy thử đăng xuất lại.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    username.dispose();
    password.dispose();
    api.client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSession = session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Agri-Tracker'),
        actions: [
          if (session != null)
            IconButton(
              onPressed: busy ? null : logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
            Expanded(
              child: session == null
                  ? LoginScreen(
                      username: username,
                      password: password,
                      busy: busy,
                      login: login,
                    )
                  : MyPlotsScreen(
                      session: session!,
                      result: result,
                      busy: busy,
                      refresh: () async {
                        if (!busy) await refresh();
                      },
                      prepareOfflineCatalog: prepareOfflineCatalog,
                      cache: cache,
                      catalogRepository: FarmerCatalogRepository(api, cache),
                      readAccessToken: () async =>
                          identical(session, screenSession)
                          ? screenSession?.token
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
