import 'package:barcode_widget/barcode_widget.dart';
import 'package:cardabase/data/hive.dart';
import 'package:hive_ce/hive.dart';

class BarcodeTypeAdapter implements TypeAdapter<BarcodeType> {
  const BarcodeTypeAdapter();

  @override
  int get typeId => HiveTypeIds.barcodeType;

  @override
  BarcodeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BarcodeType.CodeITF16;
      case 1:
        return BarcodeType.CodeITF14;
      case 2:
        return BarcodeType.CodeEAN13;
      case 3:
        return BarcodeType.CodeEAN8;
      case 4:
        return BarcodeType.CodeEAN5;
      case 5:
        return BarcodeType.CodeEAN2;
      case 6:
        return BarcodeType.CodeISBN;
      case 7:
        return BarcodeType.Code39;
      case 8:
        return BarcodeType.Code93;
      case 9:
        return BarcodeType.CodeUPCA;
      case 10:
        return BarcodeType.CodeUPCE;
      case 11:
        return BarcodeType.Code128;
      case 12:
        return BarcodeType.GS128;
      case 13:
        return BarcodeType.Telepen;
      case 14:
        return BarcodeType.QrCode;
      case 15:
        return BarcodeType.Codabar;
      case 16:
        return BarcodeType.PDF417;
      case 17:
        return BarcodeType.DataMatrix;
      case 18:
        return BarcodeType.Aztec;
      case 19:
        return BarcodeType.Rm4scc;
      case 20:
        return BarcodeType.Postnet;
      case 21:
        return BarcodeType.Itf;
      default:
        return BarcodeType.CodeEAN13;
    }
  }

  @override
  void write(BinaryWriter writer, BarcodeType obj) {
    switch (obj) {
      case BarcodeType.CodeITF16:
        writer.writeByte(0);
      case BarcodeType.CodeITF14:
        writer.writeByte(1);
      case BarcodeType.CodeEAN13:
        writer.writeByte(2);
      case BarcodeType.CodeEAN8:
        writer.writeByte(3);
      case BarcodeType.CodeEAN5:
        writer.writeByte(4);
      case BarcodeType.CodeEAN2:
        writer.writeByte(5);
      case BarcodeType.CodeISBN:
        writer.writeByte(6);
      case BarcodeType.Code39:
        writer.writeByte(7);
      case BarcodeType.Code93:
        writer.writeByte(8);
      case BarcodeType.CodeUPCA:
        writer.writeByte(9);
      case BarcodeType.CodeUPCE:
        writer.writeByte(10);
      case BarcodeType.Code128:
        writer.writeByte(11);
      case BarcodeType.GS128:
        writer.writeByte(12);
      case BarcodeType.Telepen:
        writer.writeByte(13);
      case BarcodeType.QrCode:
        writer.writeByte(14);
      case BarcodeType.Codabar:
        writer.writeByte(15);
      case BarcodeType.PDF417:
        writer.writeByte(16);
      case BarcodeType.DataMatrix:
        writer.writeByte(17);
      case BarcodeType.Aztec:
        writer.writeByte(18);
      case BarcodeType.Rm4scc:
        writer.writeByte(19);
      case BarcodeType.Postnet:
        writer.writeByte(20);
      case BarcodeType.Itf:
        writer.writeByte(21);
    }
  }
}
