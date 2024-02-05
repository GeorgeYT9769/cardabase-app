import 'package:cardabase/util/generate_qr.dart';
import 'package:flutter/material.dart';
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
      margin: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Slidable(
        endActionPane: ActionPane(
         motion: const BehindMotion(),
         children: [
           SlidableAction(onPressed: deleteFunction,
             icon: Icons.delete,
             backgroundColor: Colors.red.shade700,
             label: 'Delete card',
           ),
         ],
        ),
        //startActionPane: ActionPane(
        //  motion: const BehindMotion(),
        //  children: [
        //    SlidableAction(onPressed: widget.copyFunction,
        //      icon: Icons.copy,
        //      backgroundColor: Theme.of(context).colorScheme.secondary,
        //      label: 'Duplicate card',
        //    ),
        //  ],
        //),
        child: SizedBox(
          height: MediaQuery.of(context).size.width / 1.59 - 30, //height of button
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
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return GenerateQR(cardid: cardnumber, sn: shopName, iconcolor: iconColor,);
                  }
              )
             ;
            },
            child: Text(shopName, style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto-Regular.ttf',
            ),),
          )
        ),
      )
    );
  }
}
