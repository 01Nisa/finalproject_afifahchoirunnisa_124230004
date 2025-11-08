// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuctionModelAdapter extends TypeAdapter<AuctionModel> {
  @override
  final int typeId = 10;

  @override
  AuctionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuctionModel(
      id: fields[0] as String?,
      metObjectId: fields[1] as int,
      title: fields[2] as String,
      artist: fields[3] as String,
      primaryImageUrl: fields[4] as String,
      minimumBid: fields[5] as double,
      currentBid: fields[6] as double?,
      location: fields[7] as String,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      auctionDate: fields[10] as DateTime,
      status: fields[11] as String?,
      totalBids: fields[12] as int?,
      isExclusive: fields[13] as bool,
      category: fields[14] as String?,
      year: fields[15] as String?,
      medium: fields[16] as String?,
      dimensions: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AuctionModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.metObjectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.primaryImageUrl)
      ..writeByte(5)
      ..write(obj.minimumBid)
      ..writeByte(6)
      ..write(obj.currentBid)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.auctionDate)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.totalBids)
      ..writeByte(13)
      ..write(obj.isExclusive)
      ..writeByte(14)
      ..write(obj.category)
      ..writeByte(15)
      ..write(obj.year)
      ..writeByte(16)
      ..write(obj.medium)
      ..writeByte(17)
      ..write(obj.dimensions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
