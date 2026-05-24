import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../models/models.dart';
import '../../components/empty_state_view.dart';
import '../../components/app_colors.dart';
import 'add_recurring_sheet.dart';

class RecurringListView extends StatefulWidget {
  const RecurringListView({Key? key}) : super(key: key);

  @override
  State<RecurringListView> createState() => _RecurringListViewState();
}

class _RecurringListViewState extends State<RecurringListView> {
  void _openAddRule() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddRecurringSheet(),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Recurring Rule'),
        content: const Text('Are you sure you want to delete this recurring rule? It will stop creating new automatic transactions.'),
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
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);
    final currencySymbol = dataStore.userSettings.currencySymbol;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Recurring',
          style: TextStyle(color: AppColors.label(context)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.plus),
          onPressed: _openAddRule,
        ),
        border: null,
      ),
      child: SafeArea(
        child: dataStore.recurringRules.isEmpty
            ? const Center(
                child: EmptyStateView(
                  icon: CupertinoIcons.refresh_thick,
                  title: 'No Recurring Transactions',
                  subtitle: 'Set up automatic transactions for subscriptions or salary.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: dataStore.recurringRules.length,
                itemBuilder: (context, index) {
                  final rule = dataStore.recurringRules[index];
                  return Dismissible(
                    key: Key(rule.id ?? ''),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (dir) => _confirmDelete(context),
                    onDismissed: (dir) async {
                      if (rule.id != null) {
                        await dataStore.deleteRecurringRule(rule.id!);
                      }
                    },
                    background: Container(
                      color: CupertinoColors.systemRed,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.white,
                      ),
                    ),
                    child: CupertinoListSection.insetGrouped(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: [
                        Opacity(
                          opacity: rule.isActive ? 1.0 : 0.6,
                          child: CupertinoListTile(
                            title: Text(
                              rule.title,
                              style: TextStyle(
                                color: AppColors.label(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${rule.frequency.label} · ${rule.type.label}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.secondaryLabel(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Next: ${DateFormat.yMMMMd().format(rule.nextDueDate)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: rule.isActive
                                        ? CupertinoColors.activeBlue
                                        : AppColors.secondaryLabel(context),
                                  ),
                                ),
                              ],
                            ),
                            additionalInfo: Text(
                              '$currencySymbol${rule.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: rule.type == TransactionType.income
                                    ? CupertinoColors.systemGreen
                                    : AppColors.label(context),
                              ),
                            ),
                            trailing: CupertinoSwitch(
                              value: rule.isActive,
                              onChanged: (val) async {
                                await dataStore.toggleRecurringRule(rule);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
