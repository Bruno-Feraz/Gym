import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/body/body_home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/shell_screen.dart';
import 'features/shopping/shopping_home_screen.dart';
import 'features/workout/plan_detail_screen.dart';
import 'features/workout/plan_form_screen.dart';
import 'features/workout/progress_screen.dart';
import 'features/workout/session_screen.dart';
import 'features/workout/workout_home_screen.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/workout',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                builder: (context, state) => const WorkoutHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const PlanFormScreen(),
                  ),
                  GoRoute(
                    path: 'exercise/:exerciseId/progress',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => ProgressScreen(
                      exerciseId: state.pathParameters['exerciseId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':planId',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => PlanDetailScreen(
                      planId: state.pathParameters['planId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootKey,
                        builder: (context, state) => PlanFormScreen(
                          planId: state.pathParameters['planId'],
                        ),
                      ),
                      GoRoute(
                        path: 'session/:sessionId',
                        parentNavigatorKey: _rootKey,
                        builder: (context, state) => SessionScreen(
                          planId: state.pathParameters['planId']!,
                          sessionId: state.pathParameters['sessionId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/body',
                builder: (context, state) => const BodyHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingHomeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
