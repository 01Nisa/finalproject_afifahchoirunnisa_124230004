part of 'tawaran_model.dart';

class TawaranModelAdapter extends TypeAdapter<TawaranModel> {
  @override
  final int typeId = 5;

  @override
  TawaranModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TawaranModel(
      id: fields[0] as String,
      lelangId: fields[1] as String,
      userId: fields[2] as String,
      hargaTawaran: fields[3] as double,
      timestamp: fields[4] as DateTime,
      isWinner: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TawaranModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lelangId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.hargaTawaran)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.isWinner);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TawaranModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
