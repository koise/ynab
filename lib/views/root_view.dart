import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/data_store.dart';
import '../components/app_colors.dart';

import 'auth/login_view.dart';
import 'auth/lock_view.dart';
import 'dashboard/dashboard_view.dart';
import 'transactions/transaction_list_view.dart';
import 'reports/reports_view.dart';
import 'budgets/budget_list_view.dart';
import 'settings/settings_view.dart';

/// Root navigation controller — auth gate → lock gate → MainTabView.
/// Mirrors RootView.swift + MainTabView.swift logic.
class RootView extends StatefulWidget {
  const RootView({Key? key}) : super(key: key);

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final dataStore = context.watch<DataStore>();

    if (!authService.isAuthenticated) {
      // Reset lock state when user logs out
      if (_isUnlocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _isUnlocked = false);
        });
      }
      return const LoginView();
    }

    if (dataStore.isLoading) {
      return const _LoadingView();
    }

    if (dataStore.userSettings.isPINEnabled && !_isUnlocked) {
      return LockView(
        onUnlocked: (success) {
          if (success) setState(() => _isUnlocked = true);
        },
      );
    }

    return const _MainTabView();
  }
}

// ─── Loading View ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 20),
            const SizedBox(height: 20),
            Text(
              'Setting up YNAB...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLabel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Tab View ────────────────────────────────────────────────────────────

class _MainTabView extends StatefulWidget {
  const _MainTabView({Key? key}) : super(key: key);

  @override
  State<_MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<_MainTabView> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final dataStore = context.read<DataStore>();
    try {
      await dataStore.seedDefaultDataIfNeeded();
      await dataStore.processDueTransactions();
    } catch (e) {
      debugPrint('MainTabView: Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.house_fill),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet_below_rectangle),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_pie_fill),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.scope),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (_) => const DashboardView(),
            );
          case 1:
            return CupertinoTabView(
              builder: (_) => const TransactionListView(),
            );
          case 2:
            return CupertinoTabView(
              builder: (_) => const ReportsView(),
            );
          case 3:
            return CupertinoTabView(
              builder: (_) => const BudgetListView(),
            );
          case 4:
            return CupertinoTabView(
              builder: (_) => const SettingsView(),
            );
          default:
            return CupertinoTabView(
              builder: (_) => const DashboardView(),
            );
        }
      },
    );
  }
}
