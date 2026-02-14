library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'get_reminders_for_user.dart';

part 'update_reminder.dart';

part 'list_public_recordings.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser () {
    return CreateUserVariablesBuilder(dataConnect, );
  }
  
  
  GetRemindersForUserVariablesBuilder getRemindersForUser () {
    return GetRemindersForUserVariablesBuilder(dataConnect, );
  }
  
  
  UpdateReminderVariablesBuilder updateReminder ({required String id, required bool isCompleted, }) {
    return UpdateReminderVariablesBuilder(dataConnect, id: id,isCompleted: isCompleted,);
  }
  
  
  ListPublicRecordingsVariablesBuilder listPublicRecordings () {
    return ListPublicRecordingsVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'neuranotteai',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
