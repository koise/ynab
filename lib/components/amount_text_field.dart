import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AmountTextField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String currencySymbol;

  const AmountTextField({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  State<AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<AmountTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value > 0 ? widget.value.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant AmountTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final double? parsedVal = double.tryParse(_controller.text);
      if (parsedVal != widget.value) {
        _controller.text = widget.value > 0 ? widget.value.toStringAsFixed(2) : '';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange(String text) {
    final filtered = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = filtered.split('.');
    String finalString = filtered;
    if (parts.length > 2) {
      finalString = '${parts[0]}.${parts.sublist(1).join()}';
    }

    if (finalString != text) {
      _controller.value = TextEditingValue(
        text: finalString,
        selection: TextSelection.collapsed(offset: finalString.length),
      );
    }

    final val = double.tryParse(finalString);
    if (val != null) {
      widget.onChanged(val);
    } else if (finalString.isEmpty) {
      widget.onChanged(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        Text(
          widget.currencySymbol,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryLabel(context),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: CupertinoTextField(
            controller: _controller,
            placeholder: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.label(context),
            ),
            decoration: null,
            cursorColor: AppColors.primary,
            onChanged: _onTextChange,
          ),
        ),
      ],
    );
  }
}
