import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../data/cardabase_db.dart';
import '../util/color_picker.dart';


class CreateCard extends StatefulWidget {
  const CreateCard({super.key});

  @override
  State<CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<CreateCard> {

  final _myBox = Hive.box('mybox');
  cardabase_db cdb = cardabase_db();

  var firstcard = Hive.box('firstcardd');

  int redValue = 158;
  int blueValue = 158;
  int greenValue = 158;

  Color cardColorPreview = Colors.grey;
  String cardTextPreview = 'Card';
  TextEditingController controller = TextEditingController();
  TextEditingController controllercardid = TextEditingController();

//functions
  Future<void> openColorPickerDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ColorPickerSecondDialog(
          cardColor: cardColorPreview,
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          cardColorPreview = value;
          redValue = cardColorPreview.red;
          greenValue = cardColorPreview.green;
          blueValue = cardColorPreview.blue;
        });
      }
    });
  }

  void saveNewCard() {
    if (controllercardid.text.length == 13 && controller.text.isNotEmpty && verifyEan13(controllercardid.text) == true ) {
      setState(() {
        cdb.myShops.add([controller.text, controllercardid.text, redValue, greenValue, blueValue]);//"9940271115298"
      });
      cdb.updateDataBase();
      Navigator.pop(context);
      controller.text = '';
      controllercardid.text = '';
      redValue = 158;
      blueValue = 158;
      greenValue = 158;
      if (firstcard.isEmpty == true) {
        firstcard.put('firstcard', true);
        Restart.restartApp();
      }
    } else if (controller.text.isEmpty == true ) {
      showToast(
          "Card name cannot be empty",
          context:context,
          duration: const Duration(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0, microseconds: 0),
          animation: StyledToastAnimation.fade,
          reverseAnimation: StyledToastAnimation.fade,
          position: const StyledToastPosition(align: Alignment.topCenter)
      );
    } else if (controllercardid.text.isEmpty == true ) {
      showToast(
          "Card ID cannot be empty",
          context:context,
          duration: const Duration(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0, microseconds: 0),
          animation: StyledToastAnimation.fade,
          reverseAnimation: StyledToastAnimation.fade,
          position: const StyledToastPosition(align: Alignment.topCenter)
      );
    } else if (verifyEan13(controllercardid.text) == false) {
      showToast(
          "The ID numbers are wrong",
          context:context,
          duration: const Duration(days: 0, hours: 0, minutes: 0, seconds: 2, milliseconds: 0, microseconds: 0),
          animation: StyledToastAnimation.fade,
          reverseAnimation: StyledToastAnimation.fade,
          position: const StyledToastPosition(align: Alignment.topCenter)
      );
    }
  }

  void cancelCard() {
    Navigator.of(context).pop();
    controller.text = '';
    controllercardid.text = '';
    redValue = 158;
    blueValue = 158;
    greenValue = 158;
  }

  bool verifyEan13(String eanCode) {
    if (eanCode.length != 13 || int.tryParse(eanCode) == null) {
      return false;
    }
    int oddSum = 0;
    int evenSum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(eanCode[i]);
      if (i % 2 == 0) {
        oddSum += digit;
      } else {
        evenSum += digit;
      }
    }
    int totalSum = oddSum + evenSum * 3;
    int checkDigit = (10 - totalSum % 10) % 10;
    return checkDigit == int.parse(eanCode[12]);
  }

//init state
  @override
  void initState() {
    if (_myBox.get('CARDLIST') == null) {
      cdb.myShops.add(['Default', '4545903166393', 158, 158, 158,]);
    } else {
      cdb.loadData();
    }

    super.initState();
  }

//structure of the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: cancelCard,),
        title: Text(
            'Add a card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'xirod',
              letterSpacing: 8,
              color: Theme.of(context).colorScheme.tertiary,
            )
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
//structure of all widgets
//card widget
      body: ListView(
          children: [
          SizedBox(
              height: MediaQuery.of(context).size.width / 1.50, //height of button
              width: MediaQuery.of(context).size.width,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColorPreview, borderRadius: BorderRadius.circular(15)),
                child: Center(
                  child: Text(cardTextPreview, style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Regular.ttf',
                      color: Colors.white,
                  ),),
                ),
              )
          ),

          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
//text field card name
                TextFormField(
                  onChanged: (String value) {
                    setState(() {
                      cardTextPreview = value;
                      redValue = cardColorPreview.red;
                      greenValue = cardColorPreview.green;
                      blueValue = cardColorPreview.blue;
                    });
                  },
                  maxLength: 10,
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    focusColor: Theme.of(context).colorScheme.primary,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    hintText: 'Card name',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontFamily: 'Roboto-Regular.ttf'),
                    prefixIcon: Icon(Icons.abc, color: Theme.of(context).colorScheme.secondary),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10,),
//text field card id
                TextFormField(
                    controller: controllercardid,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      focusColor: Theme.of(context).colorScheme.primary,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      hintText: 'Card numbers',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontFamily: 'Roboto-Regular.ttf'),
                      prefixIcon: Icon(Icons.numbers, color: Theme.of(context).colorScheme.secondary),
                      suffixIcon: IconButton(icon: Icon(Icons.photo_camera_rounded, color: Theme.of(context).colorScheme.secondary),onPressed: () async {
                        var res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SimpleBarcodeScannerPage(),
                            ));
                        setState(() {
                          if (res is String) {
                            if (res != "-1") {
                              controllercardid.text = res;
                            } else {
                              controllercardid.text = "";
                            }
                          }
                        });
                      },),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 13,
                    style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10,),
//color picker button
                Container(
                  height: 65,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary,),
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      minimumSize: const Size.fromHeight(100),
                    ),
                    onPressed: openColorPickerDialog,
                    child: Text('Pick a color', style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto-Regular.ttf',
                    ),
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
//row of buttons - Cancel, Save
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //MyButton(text: 'Cancel', onPressed: () {}, width: MediaQuery.of(context).size.width / 2 - 20, height: 75, color: Colors.red.shade700,),
                    //MyButton(text: 'Save', onPressed: () {}, width: MediaQuery.of(context).size.width / 2 - 20, height: 75, color: Colors.green.shade700,), //widget.onSave
                    Container(
                      width: MediaQuery.of(context).size.width / 2 - 30,
                      height: 75,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          side: BorderSide(color: Colors.red.shade700,),
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: const Size.fromHeight(100),
                        ),
                        onPressed: cancelCard,
                        child: Text('Cancel', style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular.ttf',
                        ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20,),
                    Container(
                      width: MediaQuery.of(context).size.width / 2 - 30,
                      height: 75,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          side: BorderSide(color: Colors.green.shade700,),
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: const Size.fromHeight(100),
                        ),
                        onPressed: saveNewCard,
                        child: Text('Save', style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto-Regular.ttf',
                        ),
                        ),
                      ),
                    ),
                  ],),
              ],
            ),
          ),

        ],),
    );
  }
}
