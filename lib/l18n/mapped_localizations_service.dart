import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_keys.dart';

class MappedLocalizationsService extends LocalizationService {
  final dynamic _data;

  MappedLocalizationsService(this._data);

  @override
  Map<ErrorCode, String> get exclusionDescriptions {
    final exclusionsList = _data["exclusionList"] as Map<String, dynamic>;

    return {
      ErrorCode.THIS_IS_A_COUNTRY: exclusionsList["this_is_a_country"],
      ErrorCode.THIS_IS_A_STATE: exclusionsList["this_is_a_state"],
      ErrorCode.THIS_IS_NOT_A_CITY: exclusionsList["this_is_not_a_city"],
      ErrorCode.RENAMED_CITY: exclusionsList["renamed_city"],
      ErrorCode.INCOMPLETE_CITY: exclusionsList["uncompleted_city"],
      ErrorCode.NOT_A_CITY: exclusionsList["not_city"],
    };
  }
}