
part of 'feedback_model.dart';

class FeedbackModelAdapter extends TypeAdapter<FeedbackModel> {
  @override
  final int typeId = 12;

  @override
  FeedbackModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedbackModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      userName: fields[2] as String,
      category: fields[3] as String,
      subject: fields[4] as String,
      message: fields[5] as String,
      rating: fields[6] as int,
      createdAt: fields[7] as DateTime?,
      status: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FeedbackModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedbackModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
