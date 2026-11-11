import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/config/firebase_configuration.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/account_repository.dart';
import 'features/auth/presentation/controllers/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Web requires explicit options; native platforms retain their existing resources.
    final options = FirebaseWebConfiguration.optionsForPlatform(isWeb: kIsWeb);
    await Firebase.initializeApp(options: options);
    final auth = FirebaseAuthRepository();
    final api = ApiClient(auth: auth);
    runApp(
      CapituloCeroApp(
        session: SessionController(
          auth: auth,
          accounts: ApiAccountRepository(api),
        ),
      ),
    );
  } on FirebaseConfigurationException catch (failure) {
    runApp(FirebaseStartupFailure(message: failure.message));
  } catch (_) {
    runApp(const FirebaseStartupFailure());
  }
}

class FirebaseStartupFailure extends StatelessWidget {
  const FirebaseStartupFailure({
    super.key,
    this.message = 'No pudimos iniciar Firebase. Revisa la configuración de esta plataforma y vuelve a intentar.',
  });
  final String message;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: main,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
