import 'package:arche/extensions/iter.dart';

typedef Version = (int, int, int);
const _empty = (0, 0, 0);

extension VersionCompare on Version {
  int get normalize => $1 * 100 + $2 * 10 + $3;

  bool operator >=(Version other) => normalize >= other.normalize;
  bool operator <=(Version other) => normalize <= other.normalize;
  bool operator >(Version other) => normalize > other.normalize;
  bool operator <(Version other) => normalize < other.normalize;
  String format(){
    return "v${$1}.${$2}.${$3}";
  }
}

Version getVersionfromString(String string) {
  if (string.startsWith('v')) {
    var iter = string.substring(1).split('.').map((e) => int.parse(e)).iterator;
    return (iter.next()!, iter.next()!, iter.next()!);
  }

  return _empty;
}
