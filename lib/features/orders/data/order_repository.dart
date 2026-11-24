import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';

class HttpOrderRepository implements OrderRepository {
  HttpOrderRepository(this._api);
  final ApiClient _api;

  @override
  Future<OrderInbox> inbox(OrderTab tab) async => OrderInbox.fromJson(await _api.get('/orders', query: {'tab': tab.query}));

  @override
  Future<OrderDetail> detail(String code) async => OrderDetail.fromJson(await _api.get('/orders/$code'));

  @override
  Future<OrderDetail> respond(String code, {required bool accept}) async =>
      OrderDetail.fromJson(await _api.post('/orders/$code/respond', body: {'accept': accept}, idempotent: true));

  @override
  Future<OrderDetail> dispatch(String code, {String? transporter, String? lrNumber, String? vehicleNo, DispatchPhoto? photo}) async => OrderDetail.fromJson(
        await _api.post('/orders/$code/dispatch', idempotent: true, body: {
          if (transporter != null && transporter.trim().isNotEmpty) 'transporter': transporter.trim(),
          if (lrNumber != null && lrNumber.trim().isNotEmpty) 'lrNumber': lrNumber.trim(),
          if (vehicleNo != null && vehicleNo.trim().isNotEmpty) 'vehicleNo': vehicleNo.trim(),
          if (photo != null) 'photo': {'base64': base64Encode(photo.bytes), 'mediaType': photo.mediaType},
        }),
      );

  @override
  Future<OrderDetail> deliver(String code) async => OrderDetail.fromJson(await _api.post('/orders/$code/deliver', idempotent: true));

  @override
  Future<OrderDetail> message(String code, String text) async =>
      OrderDetail.fromJson(await _api.post('/orders/$code/messages', body: {'text': text}, idempotent: true));

  @override
  Future<OrderDetail> requestAdvance(String code, int pct) async =>
      OrderDetail.fromJson(await _api.post('/orders/$code/advance', body: {'pct': pct}, idempotent: true));

  @override
  Future<OrderDetail> confirmAdvance(String code) async => OrderDetail.fromJson(await _api.post('/orders/$code/advance/received', idempotent: true));

  @override
  Future<Map<String, dynamic>> ewayBill(String code) => _api.get('/orders/$code/eway-bill');

  @override
  Future<Uint8List> dispatchPhoto(String code) => _api.getBytes('/orders/$code/dispatch-photo');
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) => HttpOrderRepository(ref.watch(apiClientProvider)));

final orderTabProvider = StateProvider.autoDispose<OrderTab>((_) => OrderTab.fresh);
final orderInboxProvider = FutureProvider.autoDispose((ref) => ref.watch(orderRepositoryProvider).inbox(ref.watch(orderTabProvider)));
final ewayBillProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, code) => ref.watch(orderRepositoryProvider).ewayBill(code));
final dispatchPhotoProvider = FutureProvider.autoDispose.family<Uint8List, String>((ref, code) => ref.watch(orderRepositoryProvider).dispatchPhoto(code));

/// One order, kept in sync with every action taken on it (each action returns the fresh detail).
class OrderController extends AutoDisposeFamilyAsyncNotifier<OrderDetail, String> {
  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  Future<OrderDetail> build(String code) => ref.watch(orderRepositoryProvider).detail(code);

  Future<void> respond({required bool accept}) => _apply(() => _repo.respond(arg, accept: accept));
  Future<void> dispatch({String? transporter, String? lrNumber, String? vehicleNo, DispatchPhoto? photo}) =>
      _apply(() => _repo.dispatch(arg, transporter: transporter, lrNumber: lrNumber, vehicleNo: vehicleNo, photo: photo));
  Future<void> requestAdvance(int pct) => _apply(() => _repo.requestAdvance(arg, pct));
  Future<void> confirmAdvance() => _apply(() => _repo.confirmAdvance(arg));
  Future<void> deliver() => _apply(() => _repo.deliver(arg));
  Future<void> send(String text) => _apply(() => _repo.message(arg, text));

  /// Runs an action; on failure the old detail stays and the error is rethrown for the caller to show.
  Future<void> _apply(Future<OrderDetail> Function() action) async {
    final fresh = await action();
    state = AsyncData(fresh);
    ref.invalidate(orderInboxProvider);
  }
}

final orderControllerProvider = AsyncNotifierProvider.autoDispose.family<OrderController, OrderDetail, String>(OrderController.new);
