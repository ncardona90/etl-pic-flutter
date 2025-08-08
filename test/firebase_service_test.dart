import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etl_tamizajes_app/core/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: '1:1234567890:android:abc123def456',
        messagingSenderId: '1234567890',
        projectId: 'test',
      ),
    );
  });

  test('throws if list lengths differ', () {
    final service = FirebaseService();

    expect(
      () => service.registerProcessedFiles(['hash1'], ['name1', 'name2']),
      throwsArgumentError,
    );
  });
}
