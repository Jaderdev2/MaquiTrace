const { test } = require('node:test');
const assert = require('node:assert/strict');
const { NotificationsController } = require('../dist/src/notifications/notifications.controller');
const { notifyAdmins } = require('../dist/src/notifications/notification-events');
const { TransportService } = require('../dist/src/transport/transport.service');

test('reads and updates are scoped to the authenticated user', async () => {
  const calls = [];
  const prisma = { notification: {
    findMany: async args => { calls.push(args); return []; },
    count: async args => { calls.push(args); return 0; },
    updateMany: async args => { calls.push(args); return { count: 0 }; },
  } };
  const controller = new NotificationsController(prisma);
  const request = { user: { sub: 'user-a' } };
  await controller.list(request);
  await controller.read(request, 'someone-elses-notice');
  await controller.readAll(request);
  assert.ok(calls.every(call => call.where.userId === 'user-a'));
  assert.equal(calls[2].where.id, 'someone-elses-notice');
});

test('incident recipients are selected by administrator role', async () => {
  let query, data;
  const tx = { user: { findMany: async args => { query = args; return [{ id: 'admin-1' }, { id: 'admin-2' }]; } }, notification: { createMany: async args => { data = args.data; } } };
  await notifyAdmins(tx, { type: 'incident_reported', title: 'Alert', message: 'Incident' });
  assert.equal(query.where.role.name, 'administrador');
  assert.deepEqual(data.map(item => item.userId), ['admin-1', 'admin-2']);
});

test('trip assignment writes notification inside its transaction', async () => {
  const notices = [];
  const tx = {
    machine: { findUnique: async () => ({ id: 'm1', serial: 'SER-1' }), update: async () => ({}) },
    transportTrip: { findFirst: async () => null, create: async () => ({ id: 'trip-1', transporterId: 'driver' }) },
    notification: { create: async args => { notices.push(args.data); } },
  };
  const prisma = { user: { findFirst: async () => ({ id: 'driver' }) }, $transaction: async fn => fn(tx) };
  await new TransportService(prisma).receiveMachine('m1', { transporterId: 'driver', vehicle: 'truck', destination: 'yard' });
  assert.equal(notices.length, 1);
  assert.equal(notices[0].userId, 'driver');
  assert.equal(notices[0].tripId, 'trip-1');
});


test('device registration follows the authenticated account and deletion is scoped', async () => {
  let registration, deletion;
  const prisma = { pushDevice: {
    upsert: async args => { registration = args; },
    deleteMany: async args => { deletion = args; },
  } };
  const controller = new NotificationsController(prisma);
  const request = { user: { sub: 'account-a' } };
  await controller.registerDevice(request, { token: 'device-token' });
  await controller.unregisterDevice(request, { token: 'device-token' });
  assert.equal(registration.create.userId, 'account-a');
  assert.equal(registration.update.userId, 'account-a');
  assert.deepEqual(deletion.where, { token: 'device-token', userId: 'account-a' });
});


test('push worker claims and finishes a notice even without registered devices', async () => {
  const { PushService } = require('../dist/src/notifications/push.service');
  const updates = [];
  const prisma = {
    notification: {
      findMany: async () => [{ id: 'notice-1', userId: 'user-a' }],
      updateMany: async args => { updates.push(args); return { count: 1 }; },
    },
    pushDevice: { findMany: async () => [] },
  };
  const service = new PushService(prisma);
  service.enabled = true;
  await service.process();
  assert.equal(updates.length, 2);
  assert.equal(updates[0].where.id, 'notice-1');
  assert.ok(updates[1].data.pushProcessedAt instanceof Date);
});
