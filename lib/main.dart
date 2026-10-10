import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/blocked_apps_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/task_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_task_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Auth, Firestore, Storage all share this).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        // TaskProvider re-binds to whichever user is currently signed in,
        // so switching accounts (or signing out) swaps the task list too.
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(FirestoreTaskService()),
          update: (_, auth, taskProvider) {
            taskProvider!.bindToUser(auth.uid);
            return taskProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => BlockedAppsProvider()),
      ],
      child: const FocusLockApp(),
    ),
  );
}
