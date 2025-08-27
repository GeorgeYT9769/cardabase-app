import 'package:cardabase/util/read_barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/cardabase_db.dart';
import '../util/color_picker.dart';

enum CardType {
  code39('Code 39', 'code39'),
  code93('Code 93', 'code93'),
  code128('Code 128', 'code128'),
  ean13('EAN-13', 'ean13'),
  ean8('EAN-8', 'ean8'),
  ean5('EAN-5', 'ean5'),
  ean2('EAN-2', 'ean2'),
  itf('ITF', 'itf'),
  itf14('ITF-14', 'itf14'),
  itf16('ITF-16', 'itf16'),
  upca('UPC-A', 'upca'),
  upce('UPC-E', 'upce'),
  codabar('Codabar', 'codabar'),
  qrcode('QR-Code', 'qrcode'),
  datamatrix('Data Matrix', 'datamatrix'),
  aztec('Aztec', 'aztec');

  const CardType(this.label, this.type);
  final String label;
  final String type;
}

class EditCard extends StatefulWidget {

  Color cardColorPreview;
  int redValue;
  int greenValue;
  int blueValue;
  bool hasPassword;
  int index;
  String cardTextPreview;
  String cardName;
  String cardId;
  String cardType;
  List<dynamic> tags;

  EditCard({super.key, required this.cardColorPreview, required this.redValue, required this.greenValue, required this.blueValue, required this.hasPassword, required this.index, required this.cardTextPreview, required this.cardName, required this.cardId, required this.cardType, required this.tags});

  @override
  State<EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<EditCard> {

  final passwordbox = Hive.box('password');

  cardabase_db cdb = cardabase_db();

  TextEditingController controller = TextEditingController();
  TextEditingController controllercardid = TextEditingController();

  late Set<String> selectedTags;

  String getBarcodeTypeText(String cardTypeText) {
    switch (cardTypeText) {
      case 'CardType.code39':
        return 'Type: CODE 39';
      case 'CardType.code93':
        return 'Type: CODE 93';
      case 'CardType.code128':
        return 'Type: CODE 128';
      case 'CardType.ean13':
        return 'Type: EAN 13';
      case 'CardType.ean8':
        return 'Type: EAN 8';
      case 'CardType.ean5':
        return 'Type: EAN 5';
      case 'CardType.ean2':
        return 'Type: EAN 2';
      case 'CardType.itf':
        return 'Type: ITF';
      case 'CardType.itf14':
        return 'Type: ITF-14';
      case 'CardType.itf16':
        return 'Type: ITF-16';
      case 'CardType.upca':
        return 'Type: UPC-A';
      case 'CardType.upce':
        return 'Type: UPC-E';
      case 'CardType.codabar':
        return 'Type: CODABAR';
      case 'CardType.qrcode':
        return 'Type: QR CODE';
      case 'CardType.datamatrix':
        return 'Type: DATA MATRIX';
      case 'CardType.aztec':
        return 'Type: AZTEC';
      default:
        return 'Card Type';
    }
  }

  final List<dynamic> allTags = Hive.box('settingsBox').get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

//functions
  Future<void> openColorPickerDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return ColorPickerSecondDialog(
          cardColor: widget.cardColorPreview,
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          widget.cardColorPreview = value;
          widget.redValue = (widget.cardColorPreview.r * 255.0).round();
          widget.greenValue = (widget.cardColorPreview.g * 255.0).round();
          widget.blueValue = (widget.cardColorPreview.b * 255.0).round();
        });
      }
    });
  }


  void saveNewCard() {
    if (controller.text.isNotEmpty && verifyEan(controllercardid.text) == true && cardTypeText != 'Card Type') {
      final now = DateTime.now();
      final uniqueId = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      setState(() {
        cdb.myShops.insert(
          widget.index + 1,
          {
            'cardName': controller.text,
            'cardId': controllercardid.text,
            'redValue': widget.redValue,
            'greenValue': widget.greenValue,
            'blueValue': widget.blueValue,
            'cardType': cardTypeText,
            'hasPassword': widget.hasPassword,
            'uniqueId': uniqueId,
            'tags': selectedTags.toList(),
          }
        );
        cdb.myShops.removeAt(widget.index);
      });
      cdb.updateDataBase();
      Navigator.pop(context);
      controller.text = '';
      controllercardid.text = '';
      widget.redValue = 158;
      widget.blueValue = 158;
      widget.greenValue = 158;
      cardTypeText = 'Card Type';
      widget.hasPassword = false;
    } else if (controller.text.isEmpty == true ) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            )  ,
            content: Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Card Name cannot be empty!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.all(5.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ));
    } else if (controllercardid.text.isEmpty == true ) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                Icon(Icons.error, size: 15, color: Colors.white,),
                SizedBox(width: 10,),
                Text('Card ID cannot be empty!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            duration: const Duration(milliseconds: 3000),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.vertical,
            backgroundColor: const Color.fromARGB(255, 237, 67, 55),
          ));
    } else if (verifyEan(controllercardid.text) == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: Row(
            children: [
              Icon(Icons.error, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Card ID contains a mistake!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
    } else if (cardTypeText == 'Card Type') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: Row(
            children: [
              Icon(Icons.error, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Card Type was not selected!', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          content: Row(
            children: [
              Icon(Icons.error, size: 15, color: Colors.white,),
              SizedBox(width: 10,),
              Text('Unknown error', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
    }
  }

  void cancelCard() {
    Navigator.of(context).pop();
    controller.text = '';
    controllercardid.text = '';
    widget.redValue = 158;
    widget.blueValue = 158;
    widget.greenValue = 158;
  }

  //CHECKING IF THE CARD CAN BE DISPLAYED
  //P.S. WRITTEN BY CHAT-GPT CUZ GOT NO IDEA HOW TO CHECK THEM MYSELF :)
  bool verifyEan(String eanCode) {
    if (cardTypeText == 'CardType.ean13') {
      if (eanCode == '9769') {
        controllercardid.text = '978020137962';
        return true;
      } else if (eanCode.length != 13 || int.tryParse(eanCode) == null) {
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
    } else if (cardTypeText == 'CardType.ean8') {
      if (eanCode.length != 8 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 7; i++) {
        int digit = int.parse(eanCode[i]);
        if (i % 2 == 0) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      int totalSum = oddSum + evenSum * 3;
      int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[7]);
    } else if (cardTypeText == 'CardType.ean5') {
      if (eanCode.length != 5) {
        return false;
      } else {
        return true;
      }
    } else if (cardTypeText == 'CardType.ean2') {
      if (eanCode.length != 2) {
        return false;
      } else {
        return true;
      }
    } else if (cardTypeText == 'CardType.itf') {
      return int.tryParse(eanCode) != null;
    } else if (cardTypeText == 'CardType.itf14') {

      if (eanCode.length != 14 || int.tryParse(eanCode) == null) {
        return false;
      }

      int sum = 0;
      for (int i = 0; i < 13; i++) {
        int digit = int.parse(eanCode[i]);
        if (i % 2 == 0) {
          sum += digit * 3;
        } else {
          sum += digit;
        }
      }

      int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(eanCode[13]);

    } else if (cardTypeText == 'CardType.itf16') {

      if (eanCode.length != 16 || int.tryParse(eanCode) == null) {
        return false;
      }

      int sum = 0;
      for (int i = 0; i < 15; i++) {
        int digit = int.parse(eanCode[i]);
        if (i % 2 == 0) {
          sum += digit * 3;
        } else {
          sum += digit;
        }
      }

      int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(eanCode[15]);
    } else if (cardTypeText == 'CardType.upca') {
      if (eanCode.length != 12 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 11; i++) {
        int digit = int.parse(eanCode[i]);
        if (i % 2 == 0) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      int totalSum = oddSum + evenSum * 3;
      int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[11]);
    } else if (cardTypeText == 'CardType.upce') {
      if (eanCode.length != 8 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 7; i++) {
        int digit = int.parse(eanCode[i]);
        if (i % 2 == 0) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      int totalSum = oddSum + evenSum * 3;
      int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[7]);
    } else {
      return true;
    }
  }

  CardType? selectedCardType;
  String cardTypeText = 'Card Type';

  void _showBarcodeSelectorDialog() async {
    CardType? result = await showDialog<CardType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Barcode Type', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 30)),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: CardType.values.length,
                itemBuilder: (BuildContext context, int index) {
                  CardType cardType = CardType.values[index];
                  return ListTile(
                    title: Text(cardType.label),
                    onTap: () {
                      Navigator.of(context).pop(cardType);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {

      setState(() {
        selectedCardType = result;
        cardTypeText = result.toString();
      });
    }
  }

//init state
  @override
  void initState() {
    cdb.loadData();
    super.initState();
    controller.text = widget.cardName;
    widget.cardTextPreview = widget.cardName;
    widget.cardColorPreview = Color.fromARGB(255, widget.redValue, widget.greenValue, widget.blueValue);
    controllercardid.text = widget.cardId;
    widget.redValue = widget.redValue;
    widget.greenValue = widget.greenValue;
    widget.blueValue = widget.blueValue;
    cardTypeText = widget.cardType;
    widget.hasPassword = widget.hasPassword;
    selectedTags = Set<String>.from(widget.tags.map((e) => e.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.secondary,),
          onPressed: () async {
            var result = await Navigator.push(
                context, MaterialPageRoute(
              builder: (context) => const QRBarReader(),
            ));
            setState(() {
              if (result is String) {
                if (result != "-1") {
                  //controllercardid.text = result;

                  List<String> rawList = result.replaceAll("[", "").replaceAll("]", "").split(", ");

                  String name = rawList[0];
                  String number = rawList[1];
                  int red = int.parse(rawList[2]);
                  int green = int.parse(rawList[3]);
                  int blue = int.parse(rawList[4]);
                  String cardType = rawList[5];
                  bool hasPwd = rawList[6] == "true";
                  List<String> tags = rawList.sublist(7);

                  setState(() {
                    controller.text = name;
                    widget.cardTextPreview = name;
                    widget.cardColorPreview = Color.fromARGB(255, red, green, blue);
                    controllercardid.text = number;
                    widget.redValue = red;
                    widget.greenValue = green;
                    widget.blueValue = blue;
                    cardTypeText = cardType;
                    widget.hasPassword = hasPwd;
                  });
                }
              }
            });
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.secondary,), onPressed: cancelCard,),
        ],
        title: Text(
            'Edit card',
            style: Theme.of(context).textTheme.titleLarge?.copyWith()
        ),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
//structure of all widgets
//card widget
      body: ListView(
        physics: BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.width / 1.50, //height of button
              width: MediaQuery.of(context).size.width,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: widget.cardColorPreview, borderRadius: BorderRadius.circular(15)),
                child: Center(
                  child: Wrap(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Text(
                            widget.cardTextPreview,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
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
                      widget.cardTextPreview = value;
                      widget.redValue = (widget.cardColorPreview.r * 255.0).round();
                      widget.greenValue = (widget.cardColorPreview.g * 255.0).round();
                      widget.blueValue = (widget.cardColorPreview.b * 255.0).round();
                    });
                  },
                  //maxLength: 20,
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                    focusColor: Theme.of(context).colorScheme.primary,
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                    labelText: 'Card Name',
                    labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary),
                    prefixIcon: Icon(Icons.abc, color: Theme.of(context).colorScheme.secondary),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20,),
//text field card id
                TextFormField(
                    controller: controllercardid,
                    inputFormatters:  selectedCardType == CardType.qrcode
                        ? null
                        : [
                      FilteringTextInputFormatter.deny(RegExp(r'[ \.,\-]')),
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 2.0)),
                      focusColor: Theme.of(context).colorScheme.primary,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0), borderRadius: BorderRadius.circular(10)),
                      labelText: 'Card ID',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.secondary,),
                      prefixIcon: Icon(Icons.numbers, color: Theme.of(context).colorScheme.secondary),
                      suffixIcon: IconButton(icon: Icon(Icons.photo_camera_rounded, color: Theme.of(context).colorScheme.secondary),
                        onPressed: () async {
                          var result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRBarReader(),
                              ));
                          setState(() {
                            if (result is String) {
                              if (result != "-1") {
                                controllercardid.text = result;
                              } else {
                                controllercardid.text = "";
                              }
                            }
                          });
                        },),
                    ),
                    keyboardType: TextInputType.number,
                    //maxLength: 13,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20,),
                Bounceable(
                  onTap: () {},
                  child: SizedBox(
                    height: 60,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary,),
                        backgroundColor: Colors.transparent,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(100),
                      ),
                      onPressed: _showBarcodeSelectorDialog,
                      child: Text(getBarcodeTypeText(cardTypeText), style: Theme.of(context).textTheme.bodyLarge?.copyWith( //cardTypeText
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
//color picker button
                Bounceable(
                  onTap: () {},
                  child: SizedBox(
                    height: 60,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary,),
                        backgroundColor: Colors.transparent,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(100),
                      ),
                      onPressed: openColorPickerDialog,
                      child: Text('Card Color', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                    scrollDirection: Axis.horizontal,
                    itemCount: allTags.length,
                    itemBuilder: (context, chipIndex) {
                      final tag = allTags[chipIndex].toString();
                      final isSelected = selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: ActionChip(
                          label: Text(tag),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                selectedTags.remove(tag);
                              } else {
                                selectedTags.add(tag);
                              }
                            });
                          },
                          labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.inverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          avatar: isSelected
                              ? Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.onPrimary)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10,),
                passwordbox.isNotEmpty
                    ? CheckboxListTile(
                    value: widget.hasPassword,
                    title: Text('Use a password for this card', style: Theme.of(context).textTheme.bodyLarge?.copyWith( //cardTypeText
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.tertiary
                    )),
                    controlAffinity: ListTileControlAffinity.leading,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (bool? checked) {
                      setState(() {
                        widget.hasPassword = checked!;
                      });
                    })
                    : const SizedBox(height: 10,),
                const SizedBox(height: 100,),
              ],
            ),
          ),
        ],),
      floatingActionButton: Bounceable(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: SizedBox(
            height: 60,
            width: double.infinity,
            child: FloatingActionButton.extended(
              elevation: 0.0,
              heroTag: 'saveFAB',
              onPressed: saveNewCard,
              tooltip: 'SAVE',
              backgroundColor: Colors.green.shade700,
              icon: Icon(Icons.check, color: Colors.white,),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: Text('SAVE', style: Theme.of(context).textTheme.bodyLarge?.copyWith( //cardTypeText
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white
              ),),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
