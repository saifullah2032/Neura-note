part of 'generated.dart';

class GetRemindersForUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetRemindersForUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetRemindersForUserData> dataDeserializer = (dynamic json)  => GetRemindersForUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetRemindersForUserData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetRemindersForUserData, void> ref() {
    
    return _dataConnect.query("GetRemindersForUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetRemindersForUserReminders {
  final String id;
  final String title;
  final String? description;
  final Timestamp reminderTime;
  final bool isCompleted;
  GetRemindersForUserReminders.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  description = json['description'] == null ? null : nativeFromJson<String>(json['description']),
  reminderTime = Timestamp.fromJson(json['reminderTime']),
  isCompleted = nativeFromJson<bool>(json['isCompleted']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRemindersForUserReminders otherTyped = other as GetRemindersForUserReminders;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    description == otherTyped.description && 
    reminderTime == otherTyped.reminderTime && 
    isCompleted == otherTyped.isCompleted;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, description.hashCode, reminderTime.hashCode, isCompleted.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    if (description != null) {
      json['description'] = nativeToJson<String?>(description);
    }
    json['reminderTime'] = reminderTime.toJson();
    json['isCompleted'] = nativeToJson<bool>(isCompleted);
    return json;
  }

  GetRemindersForUserReminders({
    required this.id,
    required this.title,
    this.description,
    required this.reminderTime,
    required this.isCompleted,
  });
}

@immutable
class GetRemindersForUserData {
  final List<GetRemindersForUserReminders> reminders;
  GetRemindersForUserData.fromJson(dynamic json):
  
  reminders = (json['reminders'] as List<dynamic>)
        .map((e) => GetRemindersForUserReminders.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRemindersForUserData otherTyped = other as GetRemindersForUserData;
    return reminders == otherTyped.reminders;
    
  }
  @override
  int get hashCode => reminders.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reminders'] = reminders.map((e) => e.toJson()).toList();
    return json;
  }

  GetRemindersForUserData({
    required this.reminders,
  });
}

