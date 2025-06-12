import 'package:cardabase/pages/generate_barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/cardabase_db.dart';
import 'vibration_provider.dart';


class CardTile extends StatefulWidget {
  final String shopName;
  final Function(BuildContext) deleteFunction;
  final String cardnumber;
  final Color cardTileColor;
  final String cardType;
  final bool hasPassword;
  final Function(BuildContext) duplicateFunction;
  final Function(BuildContext) editFunction;
  final Function(BuildContext) moveUpFunction;
  final Function(BuildContext) moveDownFunction;
  final double labelSize;
  final double borderSize;
  final double marginSize;

  int red;
  int green;
  int blue;

  CardTile({
    super.key,
    required this.shopName,
    required this.deleteFunction,
    required this.cardnumber,
    required this.cardTileColor,
    required this.cardType,
    required this.hasPassword,
    required this.red,
    required this.green,
    required this.blue,
    required this.duplicateFunction,
    required this.editFunction,
    required this.moveUpFunction,
    required this.moveDownFunction,
    required this.labelSize,
    required this.borderSize,
    required this.marginSize,
  });

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  final passwordbox = Hive.box('password');

  cardabase_db cdb = cardabase_db();

  @override
  Widget build(BuildContext context) {
    void showUnlockDialog(BuildContext context) {
      final TextEditingController controller = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Password', style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface, fontFamily: 'Roboto-Regular.ttf',) ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(width: 2.0),
                  ),
                  focusColor: Theme.of(context).colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'Roboto-Regular.ttf',
                  ),
                  prefixIcon: Icon(
                    Icons.password,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  labelText: 'Password',
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text == passwordbox.get('PW')) {
                      // Hide the keyboard explicitly
                      FocusScope.of(context).unfocus();

                      // Wait for the keyboard to close before dismissing the dialog
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateBarcode(
                              cardid: widget.cardnumber,
                              cardtext: widget.shopName,
                              cardTileColor: widget.cardTileColor,
                              cardType: widget.cardType,
                              hasPassword: widget.hasPassword,
                              red: widget.red,
                              green: widget.green,
                              blue: widget.blue,
                            ),
                          ),
                        );
                      });
                    } else {
                      VibrationProvider.vibrateSuccess();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          content: const Row(
                            children: [
                              Icon(Icons.error, size: 15, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Incorrect password!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 3000),
                          padding: const EdgeInsets.all(5.0),
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          behavior: SnackBarBehavior.floating,
                          dismissDirection: DismissDirection.vertical,
                          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                          elevation: 0.0,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(elevation: 0.0),
                  child: Text(
                    'Unlock',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Regular.ttf',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void askForPassword() {
      if (passwordbox.isNotEmpty && widget.hasPassword) {
        showUnlockDialog(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenerateBarcode(
              cardid: widget.cardnumber,
              cardtext: widget.shopName,
              cardTileColor: widget.cardTileColor,
              cardType: widget.cardType,
              hasPassword: widget.hasPassword,
              red: widget.red,
              green: widget.green,
              blue: widget.blue,
            ),
          ),
        );
      }
    }

    return Bounceable(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.all(widget.marginSize),
        alignment: Alignment.center,
        child: GestureDetector(
          onLongPress: () => _showBottomSheet(context),
          child: SizedBox(
            height: (MediaQuery.of(context).size.width - 40) / 1.586,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.cardTileColor,
                foregroundColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderSize),
                ),
              ),
              onPressed: askForPassword,
              child: Text(
                widget.shopName,
                style: TextStyle(
                  fontSize: widget.labelSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to show the custom bottom sheet menu
  void _showBottomSheet(BuildContext context) {
    VibrationProvider.vibrateSuccess();
    showModalBottomSheet(
      context: context,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Edit', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',)),
                onTap: () {
                  Navigator.pop(context);
                  widget.editFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Duplicate', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',)),
                onTap: () {
                  Navigator.pop(context);
                  widget.duplicateFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Move UP', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',)),
                onTap: () {
                  Navigator.pop(context);
                  widget.moveUpFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.tertiary),
                title: Text('Move DOWN', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',)),
                onTap: () {
                  Navigator.pop(context);
                  widget.moveDownFunction(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove', style: TextStyle(fontFamily: 'Roboto-Regular.ttf',)),
                onTap: () {
                  Navigator.pop(context);
                  widget.deleteFunction(context);
                },
              ),
              SizedBox(
                height: 70,
              )
            ],
          ),
        );
      },
    );
  }
}
