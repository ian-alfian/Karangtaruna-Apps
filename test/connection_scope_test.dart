import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/connection_scope.dart';
import 'package:karangtaruna_apps/demo_data.dart';

void main() {
  test('Bendahara menghitung komponen koneksi tanpa menghitung ganda', () {
    final pairs = [
      ['a', 'b'],
      ['b', 'c'],
      ['a', 'c'],
      ['d', 'e'],
    ];
    expect(
      connectedHolderIds(
        role: AppRole.bendahara,
        currentUid: 'a',
        activePairs: pairs,
      ),
      {'a', 'b', 'c'},
    );
    expect(
      connectedHolderIds(
        role: AppRole.bendahara,
        currentUid: 'f',
        activePairs: pairs,
      ),
      {'f'},
    );
    expect(
      connectedHolderIds(
        role: AppRole.anggota,
        currentUid: 'member',
        activePairs: pairs,
      ),
      {'a', 'b', 'c', 'd', 'e'},
    );
  });
}
