import 'package:cardabase/pages/generate_barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CardTile extends StatefulWidget {

  final String shopName;
  Function(BuildContext)? deleteFunction;
  String cardnumber;
  Color cardTileColor;
  Color iconColor;
  String cardType;
  bool hasPassword;

  CardTile({super.key, required this.shopName, required this.deleteFunction, required this.cardnumber, required this.cardTileColor, required this.iconColor,  required this.cardType, required this.hasPassword});
  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  final passwordbox = Hive.box('password');

//required this.copyFunction
  @override
  Widget build(BuildContext context) {

    void showUnlockDialog(BuildContext context) {
      final TextEditingController controller = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                  focusColor: Theme.of(context).colorScheme.primary,
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontFamily: 'Roboto-Regular.ttf'),
                  prefixIcon: Icon(Icons.password, color: Theme.of(context).colorScheme.secondary),
                  labelText: 'Password',
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20), // Adds spacing between field and button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Example logic when button is pressed
                    if (controller.text == passwordbox.get('PW')) {
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateBarcode(cardid: widget.cardnumber, cardtext: widget.shopName, iconcolor: widget.iconColor, cardType: widget.cardType, )));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            )  ,
                            content: const Row(
                              children: [
                                Icon(Icons.error, size: 15, color: Colors.white,),
                                SizedBox(width: 10,),
                                Text('Incorrect password!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            duration: const Duration(milliseconds: 3000),
                            padding: const EdgeInsets.all(5.0),
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            behavior: SnackBarBehavior.floating,
                            dismissDirection: DismissDirection.vertical,
                            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
                          ));
                    }
                  },
                  child: Text('Unlock', style: TextStyle( //cardTypeText
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Regular.ttf',
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.tertiary
                  )),
                ),
              ),
            ],
          ),
        ),
      );
    }

    void askForPassword() {
      if (passwordbox.isNotEmpty && widget.hasPassword == true) {
        showUnlockDialog(context);
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateBarcode(cardid: widget.cardnumber, cardtext: widget.shopName, iconcolor: widget.iconColor, cardType: widget.cardType, )));
      }
    }

    return Container(
      margin: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Slidable(
        endActionPane: ActionPane(
         motion: const BehindMotion(),
         children: [
           SlidableAction(onPressed: widget.deleteFunction,
             borderRadius: BorderRadius.circular(15),
             icon: Icons.delete,
             backgroundColor: Colors.red.shade700,
             label: 'DELETE',
           ),
         ],
        ),
        child: Bounceable(
          onTap: () {},
          child: SizedBox(
            height: MediaQuery.of(context).size.width / 1.585 - 30, //height of button
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.cardTileColor,
                foregroundColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder( //to set border radius to button
                    borderRadius: BorderRadius.circular(15)
                ),
              ),
              onPressed:() {
                askForPassword();
                //Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateBarcode(cardid: cardnumber, cardtext: shopName, iconcolor: iconColor, cardType: cardType)));
              },
              child: Text(
                widget.shopName,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto-Regular.ttf',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            )
          ),
        ),
      )
    );
  }
}
