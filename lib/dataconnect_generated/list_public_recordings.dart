part of 'generated.dart';

class ListPublicRecordingsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListPublicRecordingsVariablesBuilder(this._dataConnect, );
  Deserializer<ListPublicRecordingsData> dataDeserializer = (dynamic json)  => ListPublicRecordingsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListPublicRecordingsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListPublicRecordingsData, void> ref() {
    
    return _dataConnect.query("ListPublicRecordings", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListPublicRecordingsRecordings {
  final String id;
  final String title;
  final String? category;
  final int? durationSeconds;
  ListPublicRecordingsRecordings.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  category = json['category'] == null ? null : nativeFromJson<String>(json['category']),
  durationSeconds = json['durationSeconds'] == null ? null : nativeFromJson<int>(json['durationSeconds']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPublicRecordingsRecordings otherTyped = other as ListPublicRecordingsRecordings;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    category == otherTyped.category && 
    durationSeconds == otherTyped.durationSeconds;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, category.hashCode, durationSeconds.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    if (category != null) {
      json['category'] = nativeToJson<String?>(category);
    }
    if (durationSeconds != null) {
      json['durationSeconds'] = nativeToJson<int?>(durationSeconds);
    }
    return json;
  }

  ListPublicRecordingsRecordings({
    required this.id,
    required this.title,
    this.category,
    this.durationSeconds,
  });
}

@immutable
class ListPublicRecordingsData {
  final List<ListPublicRecordingsRecordings> recordings;
  ListPublicRecordingsData.fromJson(dynamic json):
  
  recordings = (json['recordings'] as List<dynamic>)
        .map((e) => ListPublicRecordingsRecordings.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPublicRecordingsData otherTyped = other as ListPublicRecordingsData;
    return recordings == otherTyped.recordings;
    
  }
  @override
  int get hashCode => recordings.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['recordings'] = recordings.map((e) => e.toJson()).toList();
    return json;
  }

  ListPublicRecordingsData({
    required this.recordings,
  });
}

