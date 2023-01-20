import 'package:freeflow/app_config_local.dart';
import 'package:freeflow/helpers/env_config.dart';
import 'package:freeflow/helpers/environment.dart';

class AppConfig extends EnvConfig {
  late AppConfigImpl appConfig;

  AppConfig() {
    if (environment == Environment.Staging) {
      appConfig = AppConfigStaging();
    } else if (environment == Environment.Production) {
      appConfig = AppConfigProduction();
    } else if (environment == Environment.Testing) {
      appConfig = AppConfigTesting();
    } else if (environment == Environment.Local) {
      appConfig = AppConfigLocal();
    }
  }

  String deepLink() {
    return appConfig.deepLink();
  }
  String freeFlowUrl() {
    return appConfig.freeFlowUrl();
  }
}

abstract class AppConfigImpl {
  String deepLink();
  String spawnerUrl();
  String freeFlowUrl();
}

class AppConfigProduction extends AppConfigImpl {
  String deepLink() {
    return "threebot://";
  }

  String spawnerUrl() {
    return 'https://demo.freeflow.life';
  }

  String freeFlowUrl() {
    return '.demo.freeflow.life';
  }

}

class AppConfigStaging extends AppConfigImpl {
  String deepLink() {
    return "threebot://";
  }

  String spawnerUrl() {
    return 'https://digitaltwin-test.jimbertesting.be';
  }

  String freeFlowUrl() {
    return '.digitaltwin-test.jimbertesting.be';
  }
}

class AppConfigTesting extends AppConfigImpl {
  String deepLink() {
    return "threebot://";
  }

  String spawnerUrl() {
    return 'https://digitaltwin-test.jimbertesting.be';
  }

  String freeFlowUrl() {
    return '.digitaltwin-test.jimbertesting.be';
  }
}