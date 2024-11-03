import 'package:cardabase/pages/generate_barcode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CardTile extends StatelessWidget {

  final String shopName;
  Function(BuildContext)? deleteFunction;
  String cardnumber;
  Color cardTileColor;
  Color iconColor;
  //VoidCallback copyFunction;

  CardTile({super.key, required this.shopName, required this.deleteFunction, required this.cardnumber, required this.cardTileColor, required this.iconColor, });//required this.copyFunction

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Slidable(
        endActionPane: ActionPane(
         motion: const BehindMotion(),
         children: [
           SlidableAction(onPressed: deleteFunction,
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
                backgroundColor: cardTileColor,
                foregroundColor: Colors.white,
                elevation: 0.0,
                shape: RoundedRectangleBorder( //to set border radius to button
                    borderRadius: BorderRadius.circular(15)
                ),
              ),
              onPressed:() {
                Navigator.push(context, MaterialPageRoute(builder: (context) => GenerateBarcode(cardid: cardnumber, cardtext: shopName, iconcolor: iconColor)));},
              child: Text(
                shopName,
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
