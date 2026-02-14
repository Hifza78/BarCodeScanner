// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadStatusAdapter extends TypeAdapter<UploadStatus> {
  @override
  final int typeId = 0;

  @override
  UploadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UploadStatus.pending;
      case 1:
        return UploadStatus.uploading;
      case 2:
        return UploadStatus.completed;
      case 3:
        return UploadStatus.failed;
      default:
        return UploadStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, UploadStatus obj) {
    switch (obj) {
      case UploadStatus.pending:
        writer.writeByte(0);
        break;
      case UploadStatus.uploading:
        writer.writeByte(1);
        break;
      case UploadStatus.completed:
        writer.writeByte(2);
        break;
      case UploadStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UploadTaskAdapter extends TypeAdapter<UploadTask> {
  @override
  final int typeId = 1;

  @override
  UploadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadTask(
      id: fields[0] as String,
      bcn: fields[1] as String,
      description: fields[2] as String,
      photoPaths: (fields[3] as List).cast<String>(),
      barcodeImagePath: fields[4] as String?,
      status: fields[5] as UploadStatus,
      progress: fields[6] as double,
      createdAt: fields[7] as DateTime,
      completedAt: fields[8] as DateTime?,
      error: fields[9] as String?,
      driveUrl: fields[10] as String?,
      retryCount: fields[11] as int,
      lastAttemptAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UploadTask obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bcn)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.photoPaths)
      ..writeByte(4)
      ..write(obj.barcodeImagePath)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.error)
      ..writeByte(10)
      ..write(obj.driveUrl)
      ..writeByte(11)
      ..write(obj.retryCount)
      ..writeByte(12)
      ..write(obj.lastAttemptAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
