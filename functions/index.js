const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

initializeApp();

const roles = new Set(['anggota', 'bendahara', 'admin']);

async function requireActor(request, allowedRoles) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Masuk terlebih dahulu.');
  const snapshot = await getFirestore().doc(`users/${uid}`).get();
  const profile = snapshot.data();
  if (!profile || profile.isActive !== true ||
      !allowedRoles.includes(profile.role) ||
      typeof profile.organizationId !== 'string' ||
      profile.organizationId.trim() === '') {
    throw new HttpsError('permission-denied', 'Akun tidak memiliki izin untuk tindakan ini.');
  }
  return {uid, ...profile};
}

function requiredText(value, label, max = 160) {
  const text = String(value ?? '').trim();
  if (!text || text.length > max) {
    throw new HttpsError('invalid-argument', `${label} wajib diisi (maksimal ${max} karakter).`);
  }
  return text;
}

function integer(value, label, minimum = 0) {
  if (!Number.isSafeInteger(value) || value < minimum) {
    throw new HttpsError('invalid-argument', `${label} tidak valid.`);
  }
  return value;
}

function transactionDate(value, label) {
  const date = new Date(value);
  if (typeof value !== 'string' || !Number.isFinite(date.getTime()) ||
      date.getTime() > Date.now() + 86400000 ||
      date.getTime() < new Date('2020-01-01').getTime()) {
    throw new HttpsError('invalid-argument', `${label} tidak valid.`);
  }
  return date;
}

function dueDate(value) {
  const date = new Date(value);
  if (typeof value !== 'string' || !Number.isFinite(date.getTime()) ||
      date.getTime() < Date.now() - 86400000 ||
      date.getTime() > Date.now() + 5 * 365 * 86400000) {
    throw new HttpsError('invalid-argument', 'Tanggal kembali tidak valid.');
  }
  return date;
}

function audit(tx, db, actor, action, targetId, details = {}) {
  tx.set(db.collection('auditLogs').doc(), {
    organizationId: actor.organizationId,
    actorUid: actor.uid,
    action,
    targetId,
    details,
    at: FieldValue.serverTimestamp(),
  });
}

exports.recordTransaction = onCall(
  {region: 'asia-southeast2', maxInstances: 10},
  async (request) => {
    const actor = await requireActor(request, ['bendahara']);
    const data = request.data ?? {};
    const type = data.type;
    if (type !== 'income' && type !== 'expense') {
      throw new HttpsError('invalid-argument', 'Jenis transaksi tidak valid.');
    }
    const title = requiredText(data.title, 'Sumber dana/keperluan');
    const category = requiredText(data.category, 'Kategori', 80);
    const amount = integer(data.amount, 'Nominal', 1);
    const note = String(data.note ?? '').trim();
    if (note.length > 1000) {
      throw new HttpsError('invalid-argument', 'Catatan terlalu panjang.');
    }
    const date = transactionDate(data.transactionDate, 'Tanggal transaksi');
    const db = getFirestore();
    const accountRef = db.doc(`cashAccounts/${actor.uid}`);
    const transactionRef = db.collection('financialTransactions').doc();
    await db.runTransaction(async (tx) => {
      const account = await tx.get(accountRef);
      if (account.exists && account.data().organizationId !== actor.organizationId) {
        throw new HttpsError('permission-denied', 'Kas berada di organisasi lain.');
      }
      const balance = account.exists ? integer(account.data().balance, 'Saldo') : 0;
      const nextBalance = balance + (type === 'income' ? amount : -amount);
      if (nextBalance < 0) {
        throw new HttpsError('failed-precondition', 'Saldo tidak mencukupi.');
      }
      tx.set(accountRef, {
        organizationId: actor.organizationId,
        holderUid: actor.uid,
        holderName: actor.name ?? actor.email ?? '',
        balance: nextBalance,
        updatedAt: FieldValue.serverTimestamp(),
      });
      tx.create(transactionRef, {
        organizationId: actor.organizationId,
        holderUid: actor.uid,
        holderName: actor.name ?? actor.email ?? '',
        type, title, category, amount, note,
        transactionDate: date,
        createdBy: actor.uid,
        createdAt: FieldValue.serverTimestamp(),
      });
      audit(tx, db, actor, 'finance.create', transactionRef.id,
          {type, amount, balanceAfter: nextBalance});
    });
    return {id: transactionRef.id};
  },
);

exports.manageInventory = onCall(
  {region: 'asia-southeast2', maxInstances: 10},
  async (request) => {
    const actor = await requireActor(request, ['admin']);
    const db = getFirestore();
    const data = request.data ?? {};
    const action = data.action;
    if (!['add', 'edit', 'adjust', 'archive', 'borrow', 'return'].includes(action)) {
      throw new HttpsError('invalid-argument', 'Tindakan inventaris tidak valid.');
    }
    const code = action === 'return' ? null :
        requiredText(data.code, 'Kode barang', 50).toUpperCase();
    if (code && !/^[A-Z0-9_-]+$/.test(code)) {
      throw new HttpsError('invalid-argument', 'Kode barang hanya boleh huruf, angka, - dan _.');
    }
    const borrowingId = action === 'return' ?
        requiredText(data.borrowingId, 'ID peminjaman', 100) : null;
    const borrowingRef = borrowingId ? db.doc(`borrowings/${borrowingId}`) : null;
    const itemId = code ? `${actor.organizationId}__${code}` : null;
    const itemRef = itemId ? db.doc(`inventoryItems/${itemId}`) : null;
    const movementRef = db.collection('inventoryMovements').doc();
    const returnRef = action === 'return' ? db.collection('borrowingReturns').doc() : null;
    const newBorrowingRef = action === 'borrow' ? db.collection('borrowings').doc() : null;

    await db.runTransaction(async (tx) => {
      const borrowingSnapshot = borrowingRef ? await tx.get(borrowingRef) : null;
      if (borrowingSnapshot && (!borrowingSnapshot.exists ||
          borrowingSnapshot.data().organizationId !== actor.organizationId)) {
        throw new HttpsError('not-found', 'Peminjaman tidak ditemukan.');
      }
      const borrowing = borrowingSnapshot?.data();
      const targetCode = code ?? borrowing.itemCode;
      const targetItemRef = itemRef ??
          db.doc(`inventoryItems/${actor.organizationId}__${targetCode}`);
      const itemSnapshot = await tx.get(targetItemRef);
      const item = itemSnapshot.data();
      if (action === 'add' ? itemSnapshot.exists :
          !itemSnapshot.exists || item.organizationId !== actor.organizationId) {
        throw new HttpsError(action === 'add' ? 'already-exists' : 'not-found',
            action === 'add' ? 'Kode barang sudah digunakan.' : 'Barang tidak ditemukan.');
      }
      if (action !== 'add' && item.archived) {
        throw new HttpsError('failed-precondition', 'Barang arsip tidak dapat diubah.');
      }
      const before = item?.available ?? 0;
      let after = before;
      let reason = '';
      if (action === 'add') {
        const quantity = integer(data.quantity, 'Stok awal', 1);
        const name = requiredText(data.name, 'Nama barang');
        const category = requiredText(data.category, 'Kategori', 80);
        const location = requiredText(data.location, 'Lokasi', 160);
        after = quantity;
        reason = 'Stok awal';
        tx.create(targetItemRef, {
          organizationId: actor.organizationId, code: targetCode,
          name, category, location,
          total: quantity, available: quantity, damaged: 0, lost: 0,
          archived: false, createdBy: actor.uid,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      } else if (action === 'edit') {
        const name = requiredText(data.name, 'Nama barang');
        const category = requiredText(data.category, 'Kategori', 80);
        const location = requiredText(data.location, 'Lokasi', 160);
        reason = 'Metadata diperbarui';
        tx.update(targetItemRef, {name, category, location,
          updatedAt: FieldValue.serverTimestamp()});
      } else if (action === 'adjust') {
        const delta = integer(Math.abs(data.delta), 'Perubahan stok', 1) *
            Math.sign(data.delta);
        reason = requiredText(data.reason, 'Alasan', 500);
        after = before + delta;
        if (after < 0 || item.total + delta < 0) {
          throw new HttpsError('failed-precondition', 'Stok tersedia tidak mencukupi.');
        }
        tx.update(targetItemRef, {total: item.total + delta, available: after,
          updatedAt: FieldValue.serverTimestamp()});
      } else if (action === 'archive') {
        if (item.total - item.available - item.damaged - item.lost > 0) {
          throw new HttpsError('failed-precondition',
              'Selesaikan peminjaman aktif sebelum arsip.');
        }
        reason = 'Diarsipkan oleh Admin';
        tx.update(targetItemRef, {archived: true,
          updatedAt: FieldValue.serverTimestamp()});
      } else if (action === 'borrow') {
        const quantity = integer(data.quantity, 'Jumlah pinjam', 1);
        const borrower = requiredText(data.borrower, 'Peminjam', 160);
        const dueAt = dueDate(data.dueAt);
        if (dueAt.getTime() < Date.now() - 86400000 || quantity > before) {
          throw new HttpsError('failed-precondition', 'Tanggal atau stok tidak mencukupi.');
        }
        const note = String(data.note ?? '').trim().slice(0, 1000);
        after = before - quantity;
        reason = `Dipinjam oleh ${borrower}`;
        tx.update(targetItemRef, {available: after,
          updatedAt: FieldValue.serverTimestamp()});
        tx.create(newBorrowingRef, {
          organizationId: actor.organizationId, itemCode: targetCode,
          borrower, quantity, returned: 0, dueAt, note,
          borrowedAt: FieldValue.serverTimestamp(), createdBy: actor.uid,
        });
      } else if (action === 'return') {
        const good = integer(data.good, 'Jumlah baik');
        const damaged = integer(data.damaged, 'Jumlah rusak');
        const lost = integer(data.lost, 'Jumlah hilang');
        const returned = good + damaged + lost;
        if (returned < 1 || returned > borrowing.quantity - borrowing.returned) {
          throw new HttpsError('invalid-argument', 'Jumlah kembali tidak valid.');
        }
        const note = String(data.note ?? '').trim();
        if ((damaged || lost) && !note) {
          throw new HttpsError('invalid-argument',
              'Catatan wajib untuk barang rusak atau hilang.');
        }
        after = before + good;
        reason = `Baik ${good}, rusak ${damaged}, hilang ${lost}. ${note}`;
        tx.update(targetItemRef, {
          available: after, damaged: item.damaged + damaged,
          lost: item.lost + lost, updatedAt: FieldValue.serverTimestamp(),
        });
        tx.update(borrowingRef, {returned: borrowing.returned + returned,
          updatedAt: FieldValue.serverTimestamp()});
        tx.create(returnRef, {organizationId: actor.organizationId,
          borrowingId, itemCode: targetCode, good, damaged, lost, note,
          returnedAt: FieldValue.serverTimestamp(), returnedBy: actor.uid});
      }
      tx.create(movementRef, {
        organizationId: actor.organizationId, itemCode: targetCode,
        action, reason, beforeAvailable: before, afterAvailable: after,
        actorUid: actor.uid, at: FieldValue.serverTimestamp(),
      });
      audit(tx, db, actor, `inventory.${action}`, targetCode,
          {beforeAvailable: before, afterAvailable: after});
    });
    return {ok: true};
  },
);

exports.createManagedUser = onCall(
  {region: 'asia-southeast2', maxInstances: 3},
  async (request) => {
    const actorUid = request.auth?.uid;
    if (!actorUid) {
      throw new HttpsError('unauthenticated', 'Masuk sebagai Admin terlebih dahulu.');
    }

    const db = getFirestore();
    const actorSnapshot = await db.doc(`users/${actorUid}`).get();
    const actor = actorSnapshot.data();
    if (actor?.role !== 'admin' || actor?.isActive !== true ||
        typeof actor.organizationId !== 'string' ||
        actor.organizationId.trim() === '') {
      throw new HttpsError('permission-denied', 'Hanya Admin aktif yang dapat membuat akun.');
    }

    const name = String(request.data?.name ?? '').trim();
    const email = String(request.data?.email ?? '').trim().toLowerCase();
    const role = String(request.data?.role ?? '').trim().toLowerCase();
    if (name.length < 2 || name.length > 80 ||
        email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
        !roles.has(role)) {
      throw new HttpsError('invalid-argument', 'Nama, email, atau peran tidak valid.');
    }

    let user;
    try {
      user = await getAuth().createUser({
        email,
        displayName: name,
        emailVerified: false,
        disabled: false,
      });
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        throw new HttpsError('already-exists', 'Email sudah digunakan.');
      }
      throw error;
    }

    try {
      const batch = db.batch();
      batch.set(db.doc(`users/${user.uid}`), {
        name,
        email,
        role,
        organizationId: actor.organizationId.trim(),
        isActive: true,
        createdBy: actorUid,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      batch.set(db.collection('userAudit').doc(), {
        action: 'create',
        actorUid,
        targetUid: user.uid,
        organizationId: actor.organizationId.trim(),
        role,
        createdAt: FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (error) {
      try {
        await getAuth().deleteUser(user.uid);
      } catch (rollbackError) {
        console.error('Failed to remove orphan Auth user', user.uid, rollbackError);
      }
      throw new HttpsError('internal', 'Profil akun gagal dibuat. Coba lagi.');
    }

    return {uid: user.uid, email, role};
  },
);

exports.updateManagedUser = onCall(
  {region: 'asia-southeast2', maxInstances: 3},
  async (request) => {
    const actor = await requireActor(request, ['admin']);
    const targetUid = requiredText(request.data?.uid, 'ID pengguna', 128);
    const role = String(request.data?.role ?? '').trim().toLowerCase();
    const isActive = request.data?.isActive;
    if (!roles.has(role) || typeof isActive !== 'boolean') {
      throw new HttpsError('invalid-argument', 'Peran atau status tidak valid.');
    }
    if (targetUid === actor.uid && (role !== 'admin' || !isActive)) {
      throw new HttpsError('failed-precondition',
          'Admin tidak dapat menonaktifkan atau mengubah perannya sendiri.');
    }
    const db = getFirestore();
    const targetRef = db.doc(`users/${targetUid}`);
    await db.runTransaction(async (tx) => {
      const snapshot = await tx.get(targetRef);
      const target = snapshot.data();
      if (!target || target.organizationId !== actor.organizationId) {
        throw new HttpsError('not-found', 'Pengguna tidak ditemukan.');
      }
      tx.update(targetRef, {role, isActive,
        updatedBy: actor.uid, updatedAt: FieldValue.serverTimestamp()});
      audit(tx, db, actor, 'user.update', targetUid,
          {fromRole: target.role, role, fromActive: target.isActive, isActive});
    });
    return {ok: true};
  },
);

exports.manageTreasurerConnection = onCall(
  {region: 'asia-southeast2', maxInstances: 5},
  async (request) => {
    const actor = await requireActor(request, ['bendahara']);
    const db = getFirestore();
    const data = request.data ?? {};
    const action = data.action;
    if (action === 'list' || action === 'search') {
      const users = await db.collection('users')
          .where('organizationId', '==', actor.organizationId).limit(200).get();
      const treasurers = users.docs
          .filter((doc) => doc.data().role === 'bendahara' &&
              doc.data().isActive === true)
          .map((doc) => ({uid: doc.id, name: doc.data().name ?? '',
            email: doc.data().email ?? ''}));
      const requests = await db.collection('treasurerConnectionRequests')
          .where('organizationId', '==', actor.organizationId).limit(500).get();
      const mine = requests.docs
          .filter((doc) => doc.data().requesterId === actor.uid ||
              doc.data().recipientId === actor.uid)
          .map((doc) => ({id: doc.id, ...doc.data(),
            createdAt: doc.data().createdAt?.toDate()?.toISOString() ?? null}));
      const connected = mine.filter((entry) => entry.status === 'accepted');
      const partnerIds = connected.map((entry) =>
        entry.requesterId === actor.uid ? entry.recipientId : entry.requesterId);
      const balances = await Promise.all(partnerIds.map(async (uid) => {
        const snapshot = await db.doc(`cashAccounts/${uid}`).get();
        return {uid, balance: snapshot.data()?.balance ?? 0};
      }));
      const selfCash = await db.doc(`cashAccounts/${actor.uid}`).get();
      const query = String(data.query ?? '').trim().toLowerCase().slice(0, 80);
      return {
        selfBalance: selfCash.data()?.balance ?? 0,
        treasurers: action === 'search' && query ?
            treasurers.filter((person) => person.uid !== actor.uid &&
                (`${person.name} ${person.email}`).toLowerCase().includes(query)) :
            treasurers.filter((person) => person.uid !== actor.uid),
        requests: mine,
        balances,
      };
    }
    if (!['request', 'accept', 'reject', 'cancel', 'disconnect'].includes(action)) {
      throw new HttpsError('invalid-argument', 'Tindakan koneksi tidak valid.');
    }
    const targetUid = requiredText(data.targetUid, 'Bendahara tujuan', 128);
    if (targetUid === actor.uid) {
      throw new HttpsError('invalid-argument', 'Tidak dapat menghubungkan diri sendiri.');
    }
    const target = await db.doc(`users/${targetUid}`).get();
    if (!target.exists || target.data().organizationId !== actor.organizationId ||
        target.data().role !== 'bendahara' || target.data().isActive !== true) {
      throw new HttpsError('not-found', 'Bendahara tidak ditemukan.');
    }
    const pair = [actor.uid, targetUid].sort();
    const pairId = `${actor.organizationId}__${pair[0]}__${pair[1]}`;
    const requestRef = db.doc(`treasurerConnectionRequests/${pairId}`);
    const connectionRef = db.doc(`treasurerConnections/${pairId}`);
    await db.runTransaction(async (tx) => {
      const requestSnapshot = await tx.get(requestRef);
      const connectionSnapshot = await tx.get(connectionRef);
      const previous = requestSnapshot.data();
      if (action === 'request') {
        if (previous?.status === 'pending' || connectionSnapshot.data()?.active === true) {
          throw new HttpsError('already-exists', 'Permintaan atau koneksi sudah ada.');
        }
        tx.set(requestRef, {
          organizationId: actor.organizationId,
          requesterId: actor.uid, recipientId: targetUid,
          status: 'pending', createdAt: FieldValue.serverTimestamp(),
          respondedAt: null,
        });
        tx.set(db.collection('notifications').doc(), {
          organizationId: actor.organizationId, recipientId: targetUid,
          category: 'connection', title: 'Permintaan Koneksi Bendahara',
          body: `${actor.name ?? 'Bendahara'} ingin terhubung dengan Anda.`,
          referenceId: pairId, read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      } else if (action === 'accept' || action === 'reject') {
        if (previous?.status !== 'pending' || previous.recipientId !== actor.uid ||
            previous.requesterId !== targetUid) {
          throw new HttpsError('failed-precondition', 'Permintaan masuk tidak ditemukan.');
        }
        tx.update(requestRef, {status: action === 'accept' ? 'accepted' : 'rejected',
          respondedAt: FieldValue.serverTimestamp()});
        if (action === 'accept') {
          tx.set(connectionRef, {organizationId: actor.organizationId,
            holderIds: pair, active: true,
            joinedAt: FieldValue.serverTimestamp()});
        }
      } else if (action === 'cancel') {
        if (previous?.status !== 'pending' || previous.requesterId !== actor.uid ||
            previous.recipientId !== targetUid) {
          throw new HttpsError('failed-precondition', 'Permintaan terkirim tidak ditemukan.');
        }
        tx.update(requestRef, {status: 'cancelled',
          respondedAt: FieldValue.serverTimestamp()});
      } else {
        if (connectionSnapshot.data()?.active !== true ||
            previous?.status !== 'accepted') {
          throw new HttpsError('failed-precondition', 'Koneksi aktif tidak ditemukan.');
        }
        tx.update(connectionRef, {active: false,
          disconnectedAt: FieldValue.serverTimestamp()});
        tx.update(requestRef, {status: 'disconnected',
          respondedAt: FieldValue.serverTimestamp()});
      }
      if (action !== 'request') {
        const labels = {
          accept: 'Koneksi diterima', reject: 'Koneksi ditolak',
          cancel: 'Permintaan dibatalkan', disconnect: 'Koneksi diputuskan',
        };
        tx.set(db.collection('notifications').doc(), {
          organizationId: actor.organizationId, recipientId: targetUid,
          category: 'connection', title: labels[action],
          body: `${actor.name ?? 'Bendahara'} memperbarui koneksi Bendahara.`,
          referenceId: pairId, read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }
      audit(tx, db, actor, `connection.${action}`, pairId, {targetUid});
    });
    return {ok: true};
  },
);
