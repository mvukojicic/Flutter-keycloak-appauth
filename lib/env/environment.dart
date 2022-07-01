import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static init() async {
    await DotEnv.load(fileName: '.env');
  }

  static String? get domain {
    return env['AUTH0_DOMAIN'];
  }

  static String? get clientId {
    return env['AUTH0_CLIENT_ID'];
  }

  static String? get issuer {
    return env['AUTH0_ISSUER'];
  }

  static String? get redirectUri {
    return env['AUTH0_REDIRECT_URI'];
  }
}
