import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/data_store.dart';
import '../../services/notification_service.dart';
import '../../models/models.dart';
import '../../components/app_colors.dart';
import '../accounts/account_list_view.dart';
import '../categories/category_list_view.dart';
import '../recurring/recurring_list_view.dart';
import 'export_sheet.dart';
import 'pin_setup_sheet.dart';
import 'link_account_sheet.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final Map<String, String> _currencies = {
    'PHP': '₱',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };

  void _openPINSetup() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PINSetupSheet(),
      ),
    );
  }

  void _openExport() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ExportSheet(),
      ),
    );
  }

  void _openLinkAccount() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LinkAccountSheet(),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, AuthService authService) async {
    final bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all associated data. This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authService.deleteAccount();
    }
  }

  void _showCurrencyPicker(DataStore dataStore) {
    final keys = _currencies.keys.toList()..sort();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Currency'),
        actions: keys.map((key) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              final symbol = _currencies[key] ?? '\$';
              final settings = dataStore.userSettings.copyWith(
                currency: key,
                currencySymbol: symbol,
              );
              await dataStore.updateSettings(settings);
              if (mounted) Navigator.of(context).pop();
            },
            child: Text('$key (${_currencies[key]})'),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showThemePicker(DataStore dataStore) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Theme'),
        actions: ColorTheme.values.map((theme) {
          return CupertinoActionSheetAction(
            onPressed: () async {
              final settings = dataStore.userSettings.copyWith(colorTheme: theme);
              await dataStore.updateSettings(settings);
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(theme.label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final authService = Provider.of<AuthService>(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Settings',
          style: TextStyle(color: AppColors.label(context)),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('MANAGE'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.building_2_fill),
                  title: const Text('Accounts'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const AccountListView()),
                    );
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.tag_fill),
                  title: const Text('Categories'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const CategoryListView()),
                    );
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.refresh_thick),
                  title: const Text('Recurring'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const RecurringListView()),
                    );
                  },
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('PREFERENCES'),
              children: [
                CupertinoListTile(
                  title: const Text('Currency'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(
                    '${dataStore.userSettings.currency} (${dataStore.userSettings.currencySymbol})',
                  ),
                  onTap: () => _showCurrencyPicker(dataStore),
                ),
                CupertinoListTile(
                  title: const Text('Theme'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(dataStore.userSettings.colorTheme.label),
                  onTap: () => _showThemePicker(dataStore),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('SECURITY'),
              children: [
                CupertinoListTile(
                  title: const Text('Enable PIN'),
                  trailing: CupertinoSwitch(
                    value: dataStore.userSettings.isPINEnabled,
                    onChanged: (val) async {
                      if (val) {
                        _openPINSetup();
                      } else {
                        final settings = dataStore.userSettings.copyWith(
                          isPINEnabled: false,
                          isBiometricEnabled: false,
                        );
                        await dataStore.updateSettings(settings);
                      }
                    },
                  ),
                ),
                if (dataStore.userSettings.isPINEnabled)
                  CupertinoListTile(
                    title: const Text('Enable Face ID / Biometrics'),
                    trailing: CupertinoSwitch(
                      value: dataStore.userSettings.isBiometricEnabled,
                      onChanged: (val) async {
                        final settings = dataStore.userSettings.copyWith(
                          isBiometricEnabled: val,
                        );
                        await dataStore.updateSettings(settings);
                      },
                    ),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('NOTIFICATIONS'),
              children: [
                CupertinoListTile(
                  title: const Text('Budget & Recurring Alerts'),
                  trailing: CupertinoSwitch(
                    value: dataStore.userSettings.notificationsEnabled,
                    onChanged: (val) async {
                      bool granted = false;
                      if (val) {
                        granted = await NotificationService.requestPermission();
                      } else {
                        NotificationService.cancelAll();
                      }
                      final settings = dataStore.userSettings.copyWith(
                        notificationsEnabled: granted,
                      );
                      await dataStore.updateSettings(settings);
                    },
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('EXPORT'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.share),
                  title: const Text('Export Transactions'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _openExport,
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('ACCOUNT'),
              children: [
                if (authService.isAnonymous) ...[
                  const CupertinoListTile(
                    title: Text('Guest User'),
                    additionalInfo: Text(
                      'Not Backed Up',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                  CupertinoListTile(
                    title: const Text('Link Email Account'),
                    trailing: const CupertinoListTileChevron(),
                    onTap: _openLinkAccount,
                  ),
                ] else
                  CupertinoListTile(
                    title: const Text('Email'),
                    additionalInfo: Text(authService.user?.email ?? 'Linked'),
                  ),
                CupertinoListTile(
                  title: const Text('Sign Out'),
                  onTap: () async {
                    await authService.signOut();
                  },
                ),
                CupertinoListTile(
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: CupertinoColors.systemRed),
                  ),
                  onTap: () => _deleteAccount(context, authService),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
