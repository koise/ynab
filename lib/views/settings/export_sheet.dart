import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_store.dart';
import '../../services/export_service.dart';
import '../../components/app_colors.dart';

class ExportSheet extends StatefulWidget {
  const ExportSheet({Key? key}) : super(key: key);

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _exportFormat = 'CSV';

  void _showDatePicker({required bool isStart}) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppColors.secondarySystemBackground(context),
        child: Column(
          children: [
            Container(
              color: AppColors.tertiarySystemBackground(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: isStart ? _startDate : _endDate,
                onDateTimeChanged: (val) {
                  setState(() {
                    if (isStart) {
                      _startDate = val;
                    } else {
                      _endDate = val;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    final dataStore = Provider.of<DataStore>(context, listen: false);

    final filtered = dataStore.transactions.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final currencySymbol = dataStore.userSettings.currencySymbol;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (_exportFormat == 'CSV') {
      final csvString = ExportService.generateCSV(
        transactions: filtered,
        accounts: dataStore.accounts,
        categories: dataStore.categories,
      );
      final bytes = const Utf8Encoder().convert(csvString);
      await ExportService.shareFile(
        bytes: bytes,
        filename: 'YNAB_Export_$timestamp.csv',
        mimeType: 'text/csv',
      );
    } else {
      final pdfBytes = await ExportService.generatePDF(
        transactions: filtered,
        accounts: dataStore.accounts,
        categories: dataStore.categories,
        currencySymbol: currencySymbol,
        startDate: _startDate,
        endDate: _endDate,
      );
      await ExportService.shareFile(
        bytes: pdfBytes,
        filename: 'YNAB_Export_$timestamp.pdf',
        mimeType: 'application/pdf',
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Export Data',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('DATE RANGE'),
              children: [
                CupertinoListTile(
                  title: const Text('Start Date'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(DateFormat.yMMMMd().format(_startDate)),
                  onTap: () => _showDatePicker(isStart: true),
                ),
                CupertinoListTile(
                  title: const Text('End Date'),
                  trailing: const CupertinoListTileChevron(),
                  additionalInfo: Text(DateFormat.yMMMMd().format(_endDate)),
                  onTap: () => _showDatePicker(isStart: false),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('FORMAT'),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<String>(
                      groupValue: _exportFormat,
                      onValueChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _exportFormat = val;
                          });
                        }
                      },
                      children: const {
                        'CSV': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('CSV'),
                        ),
                        'PDF': Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('PDF'),
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Center(
                    child: Text(
                      'Export Transactions',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: _export,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
