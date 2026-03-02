import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/util/barcode_type_extensions.dart';
import 'package:flutter/material.dart';

class BarcodeTypeSelectorDialog extends StatelessWidget {
  const BarcodeTypeSelectorDialog({
    super.key,
    this.allowedTypes,
  });

  final List<BarcodeType>? allowedTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowedTypes = this.allowedTypes ?? BarcodeType.values;
    return AlertDialog(
      title: Text(
        'Barcode Type',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.inverseSurface,
          fontSize: 30,
        ),
      ),
      content: SizedBox(
        height: 300,
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: allowedTypes.length,
          itemBuilder: (context, index) {
            final type = allowedTypes[index];
            return ListTile(
              title: Text(type.getLabel()),
              onTap: () => Navigator.of(context).pop(type),
            );
          },
        ),
      ),
    );
  }
}
