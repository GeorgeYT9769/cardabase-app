import 'dart:io';

import 'package:cardabase/data/cardabase_db.dart';
import 'package:cardabase/util/camera_controller.dart';
import 'package:cardabase/util/color_picker.dart';
import 'package:cardabase/util/dashed_rect.dart';
import 'package:cardabase/util/read_barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

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
  final Color cardColorPreview;
  final int redValue;
  final int greenValue;
  final int blueValue;
  final bool hasPassword;
  final int index;
  final String cardTextPreview;
  final String cardName;
  final String cardId;
  final String cardType;
  final List<dynamic> tags;
  final String notes;
  final String frontFacePath;
  final String backFacePath;
  final bool useFrontFaceOverlay;
  final bool hideTitle;

  const EditCard({
    super.key,
    required this.cardColorPreview,
    required this.redValue,
    required this.greenValue,
    required this.blueValue,
    required this.hasPassword,
    required this.index,
    required this.cardTextPreview,
    required this.cardName,
    required this.cardId,
    required this.cardType,
    required this.tags,
    required this.notes,
    required this.frontFacePath,
    required this.backFacePath,
    required this.useFrontFaceOverlay,
    required this.hideTitle,
  });

  @override
  State<EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<EditCard> {
  final passwordbox = Hive.box('password');

  CardabaseDb cdb = CardabaseDb();

  late Color cardColorPreview;
  late int redValue;
  late int greenValue;
  late int blueValue;
  late bool hasPassword;
  late String cardTextPreview;

  TextEditingController controller = TextEditingController();
  TextEditingController controllercardid = TextEditingController();
  TextEditingController noteController = TextEditingController();

  late Set<String> selectedTags;

  late String imagePathFront;
  late String imagePathBack;
  late bool useFrontFaceOverlay;
  late bool hideTitle;

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

  final List<dynamic> allTags = Hive.box('settingsBox')
      .get('tags', defaultValue: <dynamic>[]) as List<dynamic>;

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
      if (value is Color) {
        setState(() {
          cardColorPreview = value;
          redValue = (cardColorPreview.r * 255.0).round();
          greenValue = (cardColorPreview.g * 255.0).round();
          blueValue = (cardColorPreview.b * 255.0).round();
        });
      }
    });
  }

  void saveNewCard(ThemeData theme) {
    if (controller.text.isNotEmpty &&
        verifyEan(controllercardid.text) == true &&
        cardTypeText != 'Card Type') {
      final now = DateTime.now();
      final uniqueId =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      setState(() {
        cdb.myShops.insert(widget.index + 1, {
          'cardName': controller.text,
          'cardId': controllercardid.text,
          'redValue': redValue,
          'greenValue': greenValue,
          'blueValue': blueValue,
          'cardType': cardTypeText,
          'hasPassword': hasPassword,
          'uniqueId': uniqueId,
          'tags': selectedTags.toList(),
          'note': noteController.text,
          'imagePathFront': imagePathFront,
          'imagePathBack': imagePathBack,
          'useFrontFaceOverlay': useFrontFaceOverlay,
          'hideTitle': hideTitle,
        });
        cdb.myShops.removeAt(widget.index);
      });
      cdb.updateDataBase();
      Navigator.pop(context);
      controller.text = '';
      controllercardid.text = '';
      noteController.text = '';
      redValue = 158;
      blueValue = 158;
      greenValue = 158;
      cardTypeText = 'Card Type';
      hasPassword = false;
      hideTitle = false;
    } else if (controller.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Card Name cannot be empty!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 3000),
          padding: const EdgeInsets.all(5.0),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.vertical,
          backgroundColor: const Color.fromARGB(255, 237, 67, 55),
        ),
      );
    } else if (controllercardid.text.isEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Card ID cannot be empty!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    } else if (verifyEan(controllercardid.text) == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Card ID contains a mistake!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Card Type was not selected!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(
                Icons.error,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Unknown error',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    noteController.text = '';
    redValue = 158;
    blueValue = 158;
    greenValue = 158;
  }

  Future<void> takeFrontPicture() async {
    final String? resultPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraControllerScreen()),
    );
    if (resultPath != null) {
      setState(() {
        imagePathFront = resultPath;
      });
    }
  }

  Future<void> takeBackPicture() async {
    final String? resultPath = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraControllerScreen()),
    );
    if (resultPath != null) {
      setState(() {
        imagePathBack = resultPath;
      });
    }
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
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          oddSum += digit;
        } else {
          evenSum += digit;
        }
      }
      final int totalSum = oddSum + evenSum * 3;
      final int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[12]);
    } else if (cardTypeText == 'CardType.ean8') {
      if (eanCode.length != 8 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 7; i++) {
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      final int totalSum = oddSum + evenSum * 3;
      final int checkDigit = (10 - totalSum % 10) % 10;
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
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          sum += digit * 3;
        } else {
          sum += digit;
        }
      }

      final int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(eanCode[13]);
    } else if (cardTypeText == 'CardType.itf16') {
      if (eanCode.length != 16 || int.tryParse(eanCode) == null) {
        return false;
      }

      int sum = 0;
      for (int i = 0; i < 15; i++) {
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          sum += digit * 3;
        } else {
          sum += digit;
        }
      }

      final int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(eanCode[15]);
    } else if (cardTypeText == 'CardType.upca') {
      if (eanCode.length != 12 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 11; i++) {
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      final int totalSum = oddSum + evenSum * 3;
      final int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[11]);
    } else if (cardTypeText == 'CardType.upce') {
      if (eanCode.length != 8 || int.tryParse(eanCode) == null) {
        return false;
      }
      int oddSum = 0;
      int evenSum = 0;
      for (int i = 0; i < 7; i++) {
        final int digit = int.parse(eanCode[i]);
        if (i.isEven) {
          evenSum += digit;
        } else {
          oddSum += digit;
        }
      }
      final int totalSum = oddSum + evenSum * 3;
      final int checkDigit = (10 - totalSum % 10) % 10;
      return checkDigit == int.parse(eanCode[7]);
    } else {
      return true;
    }
  }

  CardType? selectedCardType;
  String cardTypeText = 'Card Type';

  Future<void> _showBarcodeSelectorDialog(ThemeData theme) async {
    final CardType? result = await showDialog<CardType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Barcode Type',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.inverseSurface,
              fontSize: 30,
            ),
          ),
          content: SizedBox(
            height: 300,
            width: double.maxFinite,
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: CardType.values.length,
                itemBuilder: (BuildContext context, int index) {
                  final CardType cardType = CardType.values[index];
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
    super.initState();
    cdb.loadData();
    cardColorPreview = widget.cardColorPreview;
    redValue = widget.redValue;
    greenValue = widget.greenValue;
    blueValue = widget.blueValue;
    cardTypeText = widget.cardType;
    hasPassword = widget.hasPassword;
    cardTextPreview = widget.cardTextPreview;
    controller.text = widget.cardName;
    controllercardid.text = widget.cardId;
    noteController.text = widget.notes;
    selectedTags = Set<String>.from(widget.tags.map((e) => e.toString()));
    imagePathFront = widget.frontFacePath;
    imagePathBack = widget.backFacePath;
    useFrontFaceOverlay = widget.useFrontFaceOverlay;
    hideTitle = widget.hideTitle;
  }

  Color getContrastingTextColor(Color bg) {
    return bg.computeLuminance() > 0.7 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.qr_code_2,
            color: theme.colorScheme.secondary,
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRBarReader(),
              ),
            );
            setState(() {
              if (result is String) {
                if (result != '-1') {
                  final List<String> rawList = result
                      .replaceAll('[', '')
                      .replaceAll(']', '')
                      .split(', ');

                  final String name = rawList[0];
                  final String number = rawList[1];
                  final int red = int.parse(rawList[2]);
                  final int green = int.parse(rawList[3]);
                  final int blue = int.parse(rawList[4]);
                  final String cardType = rawList[5];
                  final bool hasPwd = rawList[6] == 'true';
                  final List<String> tags = rawList.sublist(7);

                  setState(() {
                    controller.text = name;
                    cardTextPreview = name;
                    cardColorPreview = Color.fromARGB(255, red, green, blue);
                    controllercardid.text = number;
                    redValue = red;
                    greenValue = green;
                    blueValue = blue;
                    cardTypeText = cardType;
                    hasPassword = hasPwd;
                    selectedTags = Set<String>.from(tags.map((e) => e));
                  });
                }
              }
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: cancelCard,
          ),
        ],
        title: Text('Edit card', style: theme.textTheme.titleLarge?.copyWith()),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
      ),
//structure of all widgets
//card widget
      body: ListView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.width / 1.50,
            width: MediaQuery.of(context).size.width,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColorPreview,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  if (useFrontFaceOverlay && imagePathFront != '')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(imagePathFront),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  Center(
                    child: Text(
                      hideTitle ? '' : cardTextPreview,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: getContrastingTextColor(cardColorPreview),
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Card Details'),
                    Tab(text: 'Others'),
                  ],
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface,
                  splashFactory: NoSplash.splashFactory,
                ),
                SizedBox(
                  height: 1000,
                  child: TabBarView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            //text field card name
                            TextFormField(
                              onChanged: (String value) {
                                setState(() {
                                  cardTextPreview = value;
                                  redValue =
                                      (cardColorPreview.r * 255.0).round();
                                  greenValue =
                                      (cardColorPreview.g * 255.0).round();
                                  blueValue =
                                      (cardColorPreview.b * 255.0).round();
                                });
                              },
                              controller: controller,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0),
                                ),
                                focusColor: theme.colorScheme.primary,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelText: 'Card Name',
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.abc,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            //text field card id
                            TextFormField(
                              controller: controllercardid,
                              inputFormatters:
                                  selectedCardType == CardType.qrcode
                                      ? null
                                      : [
                                          FilteringTextInputFormatter.deny(
                                            RegExp(r'[ .,-]'),
                                          ),
                                        ],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0),
                                ),
                                focusColor: theme.colorScheme.primary,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelText: 'Card ID',
                                labelStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.numbers,
                                  color: theme.colorScheme.secondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.photo_camera_rounded,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const QRBarReader(),
                                      ),
                                    );
                                    setState(() {
                                      if (result is String) {
                                        if (result != '-1') {
                                          controllercardid.text = result;
                                        } else {
                                          controllercardid.text = '';
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                              keyboardType: TextInputType.text,
                              //maxLength: 13,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Bounceable(
                              onTap: () {},
                              child: SizedBox(
                                height: 60,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(15),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size.fromHeight(100),
                                  ),
                                  onPressed: () {
                                    _showBarcodeSelectorDialog(theme);
                                  },
                                  child: Text(
                                    getBarcodeTypeText(cardTypeText),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      //cardTypeText
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            //color picker button
                            Bounceable(
                              onTap: () {},
                              child: SizedBox(
                                height: 60,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(15),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: const Size.fromHeight(100),
                                  ),
                                  onPressed: openColorPickerDialog,
                                  child: Text(
                                    'Card Color',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            TextField(
                              controller: noteController,
                              maxLines: 10,
                              decoration: InputDecoration(
                                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.inverseSurface,
                                  fontSize: 15,
                                ),
                                hintText: widget.notes.isEmpty
                                    ? 'Some notes...'
                                    : widget.notes,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(width: 2.0),
                                ),
                                focusColor: theme.colorScheme.primary,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (allTags.isEmpty)
                              const SizedBox.shrink()
                            else
                              SizedBox(
                                height: 40,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(
                                    decelerationRate:
                                        ScrollDecelerationRate.fast,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: allTags.length,
                                  itemBuilder: (context, chipIndex) {
                                    final tag = allTags[chipIndex] as String;
                                    final isSelected =
                                        selectedTags.contains(tag);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10),
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
                                        labelStyle:
                                            theme.textTheme.bodyLarge?.copyWith(
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme
                                                  .colorScheme.inverseSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        backgroundColor: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.surface,
                                        side: BorderSide(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                  .withValues(alpha: 0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        avatar: isSelected
                                            ? Icon(
                                                Icons.check,
                                                size: 18,
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(
                              height: 15,
                            ),
                            Bounceable(
                              onTap: takeFrontPicture,
                              child: Container(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  height:
                                      (MediaQuery.of(context).size.width - 40) /
                                          1.586,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CustomPaint(
                                        painter: DashedRect(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      // Icons and text behind the photo
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          Text(
                                            'Front face picture',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: theme
                                                  .colorScheme.inverseSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Center(
                                        child: GestureDetector(
                                          onLongPress: () {
                                            setState(() {
                                              imagePathFront = '';
                                            });
                                          },
                                          child: imagePathFront != ''
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: Image.file(
                                                    File(imagePathFront),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            Bounceable(
                              onTap: takeBackPicture,
                              child: Container(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  height:
                                      (MediaQuery.of(context).size.width - 40) /
                                          1.586,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: DashedRect(
                                      color: theme.colorScheme.primary,
                                    ),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        setState(() {
                                          imagePathBack = '';
                                        });
                                      },
                                      child: OutlinedButton(
                                        onPressed: takeBackPicture,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                            style: BorderStyle.none,
                                          ),
                                          backgroundColor: Colors.transparent,
                                          elevation: 0.0,
                                          padding: EdgeInsets.zero,
                                          // Add this to remove default padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          minimumSize:
                                              const Size.fromHeight(100),
                                          //padding: EdgeInsets.zero, // Remove internal padding
                                        ),
                                        child: imagePathBack != ''
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                child: Image.file(
                                                  File(imagePathBack),
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    color: theme
                                                        .colorScheme.secondary,
                                                  ),
                                                  Text(
                                                    'Back face picture',
                                                    style: theme
                                                        .textTheme.bodyLarge
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: theme.colorScheme
                                                          .inverseSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            CheckboxListTile(
                              value: useFrontFaceOverlay,
                              title: Text(
                                'Use front face picture as a card thumbnail',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  //cardTypeText
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.inverseSurface,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              side:
                                  BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (bool? checked) {
                                setState(() {
                                  useFrontFaceOverlay = checked ?? false;
                                });
                              },
                            ),
                            CheckboxListTile(
                              value: hideTitle,
                              title: Text(
                                'Hide card title',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  //cardTypeText
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: theme.colorScheme.inverseSurface,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              side:
                                  BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (bool? checked) {
                                setState(() {
                                  hideTitle = checked!;
                                });
                              },
                            ),
                            if (passwordbox.isNotEmpty)
                              CheckboxListTile(
                                value: hasPassword,
                                title: Text(
                                  'Use the password for this card',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    //cardTypeText
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.colorScheme.inverseSurface,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    hasPassword = checked!;
                                  });
                                },
                              )
                            else
                              const SizedBox(
                                height: 10,
                              ),
                            const SizedBox(
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              onPressed: () => saveNewCard(theme),
              tooltip: 'SAVE',
              backgroundColor: Colors.green.shade700,
              icon: const Icon(
                Icons.check,
                color: Colors.white,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: Text(
                'SAVE',
                style: theme.textTheme.bodyLarge?.copyWith(
                  //cardTypeText
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
