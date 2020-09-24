import 'package:lets_play_cities/base/data/app_version.dart';
import 'package:package_info/package_info.dart';

/// Retrieves client application version
Future<VersionInfo> getAppVersion() async {
  var packageInfo = await PackageInfo.fromPlatform();

  var version = packageInfo.version;
  var buildNumber = packageInfo.buildNumber;

  return VersionInfo(version, int.parse(buildNumber) ?? 0);
}
