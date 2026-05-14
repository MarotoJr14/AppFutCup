import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/storage/secure_storage.dart';

class SessionLifecycle extends ConsumerStatefulWidget {
  final Widget child;

  const SessionLifecycle({super.key, required this.child});

  @override
  ConsumerState<SessionLifecycle> createState() => _SessionLifecycleState();
}

class _SessionLifecycleState extends ConsumerState<SessionLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Best-effort: ensure access token isn't persisted after app is closed.
    // Note: lifecycle callbacks are not guaranteed on force-kill, so also do this here.
    // Fire-and-forget (dispose can't be async).
    SecureStorageService.clearToken();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // Best-effort: clear token when app leaves foreground / is closing.
      SecureStorageService.clearToken();
    }
    ref.read(authProvider.notifier).handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

