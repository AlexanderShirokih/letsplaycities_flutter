import 'package:lets_play_cities/base/game/scoring/scoring_fields.dart';
import 'package:meta/meta.dart';

/*
 * Group names
 */
const G_COMBO = "combo";
const G_PARTS = "tt_n_pts";
const G_ONLINE = "tt_onl";
const G_HISCORE = "hscr";
const G_FRQ_CITIES = "mst_frq_cts";
const G_BIG_CITIES = "msg_big_cts";

/*
 * Field names
 */
const F_ANDROID = "pva";
const F_PLAYER = "pvp";
const F_NETWORK = "pvn";
const F_ONLINE = "pvo";
const F_TIME = "tim";
const F_WINS = "win";
const F_LOSE = "los";
const F_P = "pval";

/*
 * Combo fields names
 */
const F_QUICK_TIME = "qt";
const F_SHORT_WORD = "sw";
const F_LONG_WORD = "lw";
const F_SAME_COUNTRY = "sc";
const F_DIFF_COUNTRY = "dc";

/*
 * Empty field value
 */
const V_EMPTY_S = "--";

/// Describes group of [ScoringField]s that have main field and secondary fields.
class ScoringGroup {
  final ScoringField main;
  final List<ScoringField> child;

  ScoringGroup({@required this.main, this.child});

  /// Finds field with [key] in [child] list.
  /// If there is no field with name [key] throws [StateError].
  ScoringField findField(String key) =>
      child.firstWhere((element) => element.name == key);
}

/// A set of [ScoringGroup]s.
class ScoringSet {
  final List<ScoringGroup> groups;

  ScoringSet({@required this.groups}) : assert(groups != null);

  factory ScoringSet.fromLegacyString(String value) => ScoringSet(
        groups: value.split(",").map(_parseLegacyLine).toList(growable: false),
      );

  static ScoringGroup _parseLegacyLine(String line) {
    final beginChild = line.indexOf('<');
    final endChild = line.indexOf('>');
    final hasChild = beginChild != -1 && endChild != -1;

    return ScoringGroup(
      main: hasChild
          ? _parseLegacyField(line.substring(0, beginChild))
          : _parseLegacyField(line),
      child: hasChild
          ? line
              .substring(beginChild + 1, endChild)
              .split('|')
              .map(_parseLegacyField)
              .toList(growable: false)
          : List<ScoringField>.empty(growable: false),
    );
  }

  static ScoringField _parseLegacyField(String line) {
    final nameValueDiv = line.indexOf('=');
    final valueKeyDiv = line.lastIndexOf('=');
    final isPaired = nameValueDiv != valueKeyDiv;

    // name => (name)
    if (nameValueDiv == -1) return EmptyScoringField(line);

    final name = line.substring(0, nameValueDiv);
    final key = line.substring(nameValueDiv + 1, isPaired ? valueKeyDiv : null);
    final intKey = int.tryParse(key);
    final value = isPaired ? int.parse(line.substring(valueKeyDiv + 1)) : null;

    // name=key=intValue => (name, key, intValue)
    if (isPaired) return PairedScoringField<String, int>(name, key, value);

    // pvalN=value => (name, value, N) | (name, value, null)
    if (intKey == null)
      return name.startsWith(F_P)
          ? PairedScoringField<String, int>(
              name, key, int.parse(name.substring(name.length - 1)))
          : PairedScoringField<String, int>(name, key, null);

    // name=intValue => (name, intValue)
    return F_TIME == name
        ? TimeScoringField(name, intKey)
        : IntScoringField(name, intKey);
  }

  factory ScoringSet.initial() => ScoringSet(
        groups: [
          ScoringGroup(
            main: ScoringField.int(name: G_PARTS),
            child: [
              ScoringField.int(name: F_ANDROID),
              ScoringField.int(name: F_PLAYER),
              ScoringField.int(name: F_NETWORK),
              ScoringField.int(name: F_ONLINE),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_ONLINE),
            child: [
              ScoringField.time(name: F_TIME),
              ScoringField.int(name: F_WINS),
              ScoringField.int(name: F_LOSE),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_COMBO),
            child: [
              ScoringField.int(name: F_QUICK_TIME),
              ScoringField.int(name: F_SHORT_WORD),
              ScoringField.int(name: F_LONG_WORD),
              ScoringField.int(name: F_SAME_COUNTRY),
              ScoringField.int(name: F_DIFF_COUNTRY),
            ],
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_FRQ_CITIES),
            child: List.generate(10,
                (i) => ScoringField.paired(name: "$F_P$i", value: V_EMPTY_S),
                growable: false),
          ),
          ScoringGroup(
            main: ScoringField.empty(name: G_BIG_CITIES),
            child: List.generate(10,
                (i) => ScoringField.paired(name: "$F_P$i", value: V_EMPTY_S),
                growable: false),
          ),
        ],
      );
}
