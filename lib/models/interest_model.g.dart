// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterestModelAdapter extends TypeAdapter<InterestModel> {
  @override
  final int typeId = 4;

  @override
  InterestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InterestModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      auctionId: fields[2] as String,
      auctionTitle: fields[3] as String,
      artistName: fields[4] as String,
      imageUrl: fields[5] as String,
      minimumBid: fields[6] as double,
      location: fields[7] as String,
      auctionDate: fields[8] as DateTime,
      isNotificationEnabled: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InterestModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.auctionId)
      ..writeByte(3)
      ..write(obj.auctionTitle)
      ..writeByte(4)
      ..write(obj.artistName)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.minimumBid)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.auctionDate)
      ..writeByte(9)
      ..write(obj.isNotificationEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
