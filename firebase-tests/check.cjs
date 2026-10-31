const fs = require('fs');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  setDoc,
  getDoc,
  deleteDoc,
  runTransaction,
  updateDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

async function main() {
  const superAdminEmail = 'ian.23eo10039@students.unugha.id';
  const env = await initializeTestEnvironment({
    projectId: 'demo-karangtaruna',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
  try {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      for (const [uid, role] of [
        ['admin', 'admin'], ['bend1', 'bendahara'],
        ['bend2', 'bendahara'], ['ZUpper', 'bendahara'],
        ['aLower', 'bendahara'], ['member', 'anggota'],
      ]) {
        await setDoc(doc(db, 'users', uid), {
          organizationId: 'org', name: uid,
          email: uid === 'admin' ? superAdminEmail : `${uid}@gmail.com`,
          role, isActive: true,
        });
      }
      await setDoc(doc(db, 'users', 'foreign'), {
        organizationId: 'other-org', name: 'foreign',
        email: 'foreign@gmail.com', role: 'anggota', isActive: true,
      });
      await setDoc(doc(db, 'users', 'blocked'), {
        organizationId: 'org', name: 'blocked',
        email: 'blocked@kampus.ac.id', role: 'anggota', isActive: true,
      });
    });
    const admin = env.authenticatedContext('admin', {
      email: superAdminEmail,
    }).firestore();
    const bend1 = env.authenticatedContext('bend1', {
      email: 'bend1@gmail.com',
    }).firestore();
    const bend2 = env.authenticatedContext('bend2', {
      email: 'bend2@gmail.com',
    }).firestore();
    const upperUidTreasurer = env.authenticatedContext('ZUpper', {
      email: 'zupper@gmail.com',
    }).firestore();
    const member = env.authenticatedContext('member', {
      email: 'member@gmail.com',
    }).firestore();
    const blocked = env.authenticatedContext('blocked', {
      email: 'blocked@kampus.ac.id',
    }).firestore();

    await assertFails(getDoc(doc(blocked, 'users', 'blocked')));

    await assertSucceeds(setDoc(doc(admin, 'users', 'newuser'), {
      organizationId: 'org', name: 'New User', email: 'new@gmail.com',
      role: 'anggota', isActive: true, createdBy: 'admin',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(admin, 'users', 'non-gmail'), {
      organizationId: 'org', name: 'Non Gmail', email: 'new@kampus.ac.id',
      role: 'anggota', isActive: true, createdBy: 'admin',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(member, 'users', 'illegal'), {
      organizationId: 'org', name: 'Illegal', email: 'illegal@gmail.com',
      role: 'admin', isActive: true, createdBy: 'member',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(admin, 'users', 'newuser'), {
      role: 'bendahara', isActive: true,
      updatedBy: 'admin', updatedAt: serverTimestamp(),
    }));

    await assertSucceeds(runTransaction(bend1, async (tx) => {
      const account = doc(bend1, 'cashAccounts', 'bend1');
      const ledger = doc(bend1, 'financialTransactions', 'first-income');
      await tx.get(account);
      tx.set(account, {organizationId: 'org', holderUid: 'bend1',
        holderName: 'bend1', balance: 100, lastTransactionId: 'first-income',
        updatedAt: serverTimestamp()});
      tx.set(ledger, {organizationId: 'org', holderUid: 'bend1',
        holderName: 'bend1', type: 'income', title: 'Iuran',
        category: 'Lainnya', amount: 100, note: '',
        transactionDate: Timestamp.now(), createdBy: 'bend1',
        createdAt: serverTimestamp()});
    }));
    await assertFails(runTransaction(bend1, async (tx) => {
      const account = doc(bend1, 'cashAccounts', 'bend1');
      const ledger = doc(bend1, 'financialTransactions', 'overspend');
      await tx.get(account);
      tx.set(account, {organizationId: 'org', holderUid: 'bend1',
        holderName: 'bend1', balance: -1, lastTransactionId: 'overspend',
        updatedAt: serverTimestamp()});
      tx.set(ledger, {organizationId: 'org', holderUid: 'bend1',
        holderName: 'bend1', type: 'expense', title: 'Belanja',
        category: 'Lainnya', amount: 101, note: '',
        transactionDate: Timestamp.now(), createdBy: 'bend1',
        createdAt: serverTimestamp()});
    }));

    await assertSucceeds(runTransaction(admin, async (tx) => {
      const item = doc(admin, 'inventoryItems', 'org__KURSI');
      const movement = doc(admin, 'inventoryMovements', 'add-kursi');
      await tx.get(item);
      tx.set(item, {organizationId: 'org', code: 'KURSI',
        name: 'Kursi', category: 'Peralatan', location: 'Gudang',
        total: 10, available: 10, damaged: 0, lost: 0,
        archived: false, hidden: false, createdBy: 'admin',
        createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
      tx.set(movement, {organizationId: 'org', itemCode: 'KURSI',
        action: 'Tambah barang', reason: 'Stok awal',
        beforeAvailable: 0, afterAvailable: 10, actorUid: 'admin',
        at: serverTimestamp()});
    }));
    const photo = doc(admin, 'inventoryPhotos', 'org__KURSI');
    await assertSucceeds(setDoc(photo, {organizationId: 'org',
      itemCode: 'KURSI', format: 'jpeg', imageBase64: 'dGVzdA==',
      updatedBy: 'admin', updatedAt: serverTimestamp()}));
    await assertSucceeds(getDoc(doc(member, 'inventoryPhotos', 'org__KURSI')));
    await assertFails(setDoc(doc(member, 'inventoryPhotos', 'org__KURSI'), {
      organizationId: 'org', itemCode: 'KURSI', format: 'jpeg',
      imageBase64: 'dGVzdA==', updatedBy: 'member',
      updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(member, 'inventoryItems', 'org__ILEGAL'), {
      organizationId: 'org', code: 'ILEGAL', name: 'Ilegal',
      category: 'Lainnya', location: 'Gudang', total: 1, available: 1,
      damaged: 0, lost: 0, archived: false, hidden: false, createdBy: 'member',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(runTransaction(admin, async (tx) => {
      const item = doc(admin, 'inventoryItems', 'org__KURSI');
      const borrowing = doc(admin, 'borrowings', 'pinjam-kursi');
      const movement = doc(admin, 'inventoryMovements', 'borrow-kursi');
      await tx.get(item);
      tx.update(item, {available: 8, updatedAt: serverTimestamp()});
      tx.set(borrowing, {organizationId: 'org', itemCode: 'KURSI',
        borrower: 'Warga', quantity: 2, returned: 0,
        dueAt: Timestamp.now(), note: '', borrowedAt: serverTimestamp(),
        createdBy: 'admin'});
      tx.set(movement, {organizationId: 'org', itemCode: 'KURSI',
        action: 'Peminjaman', reason: 'Dipinjam oleh Warga',
        beforeAvailable: 10, afterAvailable: 8,
        actorUid: 'admin', at: serverTimestamp()});
    }));
    await assertSucceeds(runTransaction(admin, async (tx) => {
      const borrowing = doc(admin, 'borrowings', 'pinjam-kursi');
      const item = doc(admin, 'inventoryItems', 'org__KURSI');
      const returned = doc(admin, 'borrowingReturns', 'return-kursi');
      const movement = doc(admin, 'inventoryMovements', 'return-kursi');
      await tx.get(borrowing);
      await tx.get(item);
      tx.update(item, {available: 9, damaged: 1,
        updatedAt: serverTimestamp()});
      tx.update(borrowing, {returned: 2,
        updatedAt: serverTimestamp()});
      tx.set(returned, {organizationId: 'org', borrowingId: 'pinjam-kursi',
        itemCode: 'KURSI', good: 1, damaged: 1, lost: 0, note: 'Rusak',
        returnedAt: serverTimestamp(), returnedBy: 'admin'});
      tx.set(movement, {organizationId: 'org', itemCode: 'KURSI',
        action: 'Pengembalian', reason: 'Baik 1, rusak 1',
        beforeAvailable: 8, afterAvailable: 9,
        actorUid: 'admin', at: serverTimestamp()});
    }));

    const pairId = 'org__bend1__bend2';
    // UID Firebase yang berisi huruf besar dan kecil harus memakai urutan
    // pasangan yang sama seperti perhitungan String.sort() di aplikasi.
    await assertSucceeds(runTransaction(upperUidTreasurer, async (tx) => {
      const request = doc(upperUidTreasurer,
        'treasurerConnectionRequests', 'org__ZUpper__aLower');
      const connection = doc(upperUidTreasurer,
        'treasurerConnections', 'org__ZUpper__aLower');
      await tx.get(request);
      await tx.get(connection);
      tx.set(request, {organizationId: 'org', requesterId: 'ZUpper',
        recipientId: 'aLower', status: 'pending',
        createdAt: serverTimestamp(), respondedAt: null});
    }));
    await assertSucceeds(runTransaction(bend1, async (tx) => {
      const request = doc(bend1, 'treasurerConnectionRequests', pairId);
      const connection = doc(bend1, 'treasurerConnections', pairId);
      await tx.get(request);
      await tx.get(connection);
      tx.set(request, {organizationId: 'org', requesterId: 'bend1',
        recipientId: 'bend2', status: 'pending',
        createdAt: serverTimestamp(), respondedAt: null});
      tx.set(doc(bend1, 'notifications', 'request-notification'), {
        organizationId: 'org', recipientId: 'bend2', sourceUid: 'bend1',
        category: 'connection', title: 'Permintaan Koneksi Bendahara',
        body: 'bend1 memperbarui koneksi Bendahara.',
        referenceId: pairId, read: false, createdAt: serverTimestamp(),
      });
    }));
    await assertFails(setDoc(doc(bend1, 'treasurerConnectionRequests', 'duplicate'), {
      organizationId: 'org', requesterId: 'bend1', recipientId: 'bend2',
      status: 'pending', createdAt: serverTimestamp(), respondedAt: null,
    }));
    await assertSucceeds(runTransaction(bend2, async (tx) => {
      const request = doc(bend2, 'treasurerConnectionRequests', pairId);
      const connection = doc(bend2, 'treasurerConnections', pairId);
      await tx.get(request);
      await tx.get(connection);
      tx.update(request, {status: 'accepted', respondedAt: serverTimestamp()});
      tx.set(connection, {organizationId: 'org', holderIds: ['bend1', 'bend2'],
        active: true, joinedAt: serverTimestamp()});
    }));
    await assertSucceeds(runTransaction(bend1, async (tx) => {
      const request = doc(bend1, 'treasurerConnectionRequests', pairId);
      const connection = doc(bend1, 'treasurerConnections', pairId);
      await tx.get(request);
      await tx.get(connection);
      tx.update(request, {status: 'disconnected',
        respondedAt: serverTimestamp()});
      tx.update(connection, {active: false,
        disconnectedAt: serverTimestamp()});
    }));
    await assertSucceeds(runTransaction(bend2, async (tx) => {
      const request = doc(bend2, 'treasurerConnectionRequests', pairId);
      const connection = doc(bend2, 'treasurerConnections', pairId);
      await tx.get(request);
      await tx.get(connection);
      tx.set(request, {organizationId: 'org', requesterId: 'bend2',
        recipientId: 'bend1', status: 'pending',
        createdAt: serverTimestamp(), respondedAt: null});
    }));
    await assertSucceeds(runTransaction(bend1, async (tx) => {
      const request = doc(bend1, 'treasurerConnectionRequests', pairId);
      const connection = doc(bend1, 'treasurerConnections', pairId);
      await tx.get(request);
      await tx.get(connection);
      tx.update(request, {status: 'accepted', respondedAt: serverTimestamp()});
      tx.set(connection, {organizationId: 'org', holderIds: ['bend1', 'bend2'],
        active: true, joinedAt: serverTimestamp()});
    }));
    const balance = (await getDoc(doc(bend1, 'cashAccounts', 'bend1'))).data();
    if (balance.balance !== 100) throw new Error('Saldo berubah setelah gagal.');
    await assertFails(deleteDoc(doc(member, 'users', 'newuser')));
    await assertFails(deleteDoc(doc(admin, 'users', 'admin')));
    await assertFails(deleteDoc(doc(admin, 'users', 'foreign')));
    await assertSucceeds(deleteDoc(doc(admin, 'users', 'newuser')));
    console.log('Firestore rules: admin, saldo, stok, koneksi lulus.');
  } finally {
    await env.cleanup();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
