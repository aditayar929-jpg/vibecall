import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/interests_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/dating/presentation/screens/dating_screen.dart';
import '../../features/video_call/presentation/screens/matching_screen.dart';
import '../../features/video_call/presentation/screens/video_call_screen.dart';
import '../../features/video_call/presentation/screens/live_call_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/premium/presentation/screens/premium_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/interests',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/dating',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DatingScreen(),
            ),
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/matching',
        builder: (context, state) => const MatchingScreen(),
      ),
      GoRoute(
        path: '/video-call',
        builder: (context, state) {
          final callId = state.uri.queryParameters['callId'] ?? '';
          final remoteUserId = state.uri.queryParameters['remoteUserId'] ?? '';
          final isCaller = state.uri.queryParameters['isCaller'] == 'true';
          return VideoCallScreen(
            callId: callId,
            remoteUserId: remoteUserId,
            isCaller: isCaller,
          );
        },
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) {
          final chatId = state.uri.queryParameters['chatId'] ?? '';
          final name = state.uri.queryParameters['name'] ?? '';
          final avatar = state.uri.queryParameters['avatar'] ?? '';
          return ChatDetailScreen(
            chatId: chatId,
            userName: name,
            userAvatar: avatar,
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
