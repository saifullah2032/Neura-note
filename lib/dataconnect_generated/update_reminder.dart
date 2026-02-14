part of 'generated.dart';

class UpdateReminderVariablesBuilder {
  String id;
  bool isCompleted;

  final FirebaseDataConnect _dataConnect;
  UpdateReminderVariablesBuilder(this._dataConnect, {required  this.id,required  this.isCompleted,});
  Deserializer<UpdateReminderData> dataDeserializer = (dynamic json)  => UpdateReminderData.fromJson(jsonDecode(json));
  Serializer<UpdateReminderVariables> varsSerializer = (UpdateReminderVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateReminderData, UpdateReminderVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateReminderData, UpdateReminderVariables> ref() {
    UpdateReminderVariables vars= UpdateReminderVariables(id: id,isCompleted: isCompleted,);
    return _dataConnect.mutation("UpdateReminder", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateReminderReminderUpdate {
  final String id;
  UpdateReminderReminderUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReminderReminderUpdate otherTyped = other as UpdateReminderReminderUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateReminderReminderUpdate({
    required this.id,
  });
}

@immutable
class UpdateReminderData {
  final UpdateReminderReminderUpdate? reminder_update;
  UpdateReminderData.fromJson(dynamic json):
  
  reminder_update = json['reminder_update'] == null ? null : UpdateReminderReminderUpdate.fromJson(json['reminder_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReminderData otherTyped = other as UpdateReminderData;
    return reminder_update == otherTyped.reminder_update;
    
  }
  @override
  int get hashCode => reminder_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (reminder_update != null) {
      json['reminder_update'] = reminder_update!.toJson();
    }
    return json;
  }

  UpdateReminderData({
    this.reminder_update,
  });
}

@immutable
class UpdateReminderVariables {
  final String id;
  final bool isCompleted;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateReminderVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  isCompleted = nativeFromJson<bool>(json['isCompleted']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReminderVariables otherTyped = other as UpdateReminderVariables;
    return id == otherTyped.id && 
    isCompleted == otherTyped.isCompleted;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, isCompleted.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['isCompleted'] = nativeToJson<bool>(isCompleted);
    return json;
  }

  UpdateReminderVariables({
    required this.id,
    required this.isCompleted,
  });
}

