import 'demo_data.dart';

/// Mengambil kelompok bendahara yang terhubung melalui koneksi aktif.
/// Bendahara melihat kelompoknya; peran lain melihat gabungan semua kelompok.
Set<String> connectedHolderIds({
  required AppRole role,
  required String currentUid,
  required Iterable<List<String>> activePairs,
}) {
  final neighbours = <String, Set<String>>{};
  for (final pair in activePairs) {
    if (pair.length != 2 ||
        pair[0].isEmpty ||
        pair[1].isEmpty ||
        pair[0] == pair[1]) {
      continue;
    }
    neighbours.putIfAbsent(pair[0], () => <String>{}).add(pair[1]);
    neighbours.putIfAbsent(pair[1], () => <String>{}).add(pair[0]);
  }
  if (role != AppRole.bendahara) return neighbours.keys.toSet();
  final visited = <String>{currentUid};
  final queue = <String>[currentUid];
  for (var index = 0; index < queue.length; index++) {
    for (final next in neighbours[queue[index]] ?? <String>{}) {
      if (visited.add(next)) queue.add(next);
    }
  }
  return visited;
}
