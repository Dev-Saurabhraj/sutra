import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/formatters.dart';
import '../tokens.dart';
import '../typography.dart';
import 'parchi.dart';

/// Opens a form on a paper slip that rises from the bottom, above the keyboard.
Future<T?> showSutraSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: SingleChildScrollView(child: Parchi(child: child)),
    ),
  );
}

/// Title block for a sheet: a small label above a big name.
class SheetTitle extends StatelessWidget {
  const SheetTitle({super.key, required this.title, this.kicker, this.subtitle});

  final String title;
  final String? kicker;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) Text(kicker!, style: text.labelSmall),
        Text(title, style: SutraType.display(22)),
        if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: text.bodySmall)),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Big − value + control: easier than typing on a small phone.
class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.unit = '', this.step = 1, this.min = 0});

  final double value;
  final ValueChanged<double> onChanged;
  final String unit;
  final double step;
  final double min;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(icon: Icons.remove_rounded, onTap: value - step >= min ? () => onChanged(value - step) : null),
        Expanded(
          child: Text('${Fmt.qty(value)} $unit'.trim(), textAlign: TextAlign.center, style: SutraType.figure(28, color: SutraColors.sindoorDeep)),
        ),
        _RoundButton(icon: Icons.add_rounded, onTap: () => onChanged(value + step)),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
        onPressed: onTap,
        child: Icon(icon, size: 26),
      ),
    );
  }
}

class ChoiceOption<T> {
  const ChoiceOption({required this.value, required this.title, this.subtitle, this.icon, this.leading});
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
}

/// One-tap choices as big cards (not radio buttons): easier to read and to hit.
class ChoiceCards<T> extends StatelessWidget {
  const ChoiceCards({super.key, required this.options, required this.selected, required this.onSelect, this.columns = 1});

  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget card(ChoiceOption<T> o) {
      final on = o.value == selected;
      return Material(
        color: on ? SutraColors.sindoorWash : SutraColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          side: BorderSide(color: on ? SutraColors.sindoor : SutraColors.rule, width: on ? 2 : 1.2),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(SutraRadius.md),
          onTap: () => onSelect(o.value),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (o.leading != null) ...[o.leading!, const SizedBox(width: 12)],
                if (o.icon != null) ...[Icon(o.icon, color: on ? SutraColors.sindoor : SutraColors.neel, size: 26), const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title, style: text.titleSmall),
                      if (o.subtitle != null) Text(o.subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: SutraMotion.quick,
                  opacity: on ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded, color: SutraColors.sindoor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (columns == 1) {
      return Column(children: [for (final o in options) Padding(padding: const EdgeInsets.only(bottom: 10), child: card(o))]);
    }
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [for (final o in options) card(o)],
    );
  }
}

/// A numeric field with a label; accepts decimals.
class NumberField extends StatelessWidget {
  const NumberField({super.key, required this.label, required this.initial, required this.onChanged, this.prefix, this.suffix, this.decimals = true});

  final String label;
  final num? initial;
  final ValueChanged<double?> onChanged;
  final String? prefix;
  final String? suffix;
  final bool decimals;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial == null ? '' : Fmt.qty(initial!).replaceAll(',', ''),
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimals ? r'[0-9.]' : r'[0-9]'))],
      decoration: InputDecoration(labelText: label, prefixText: prefix, suffixText: suffix),
      style: SutraType.figure(18),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }
}
