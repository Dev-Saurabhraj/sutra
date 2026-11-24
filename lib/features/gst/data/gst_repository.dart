import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/gst_models.dart';

class HttpGstRepository implements GstRepository {
  HttpGstRepository(this._api);
  final ApiClient _api;

  @override
  Future<GstPeriods> periods() async => GstPeriods.fromJson(await _api.get('/gst/periods'));

  @override
  Future<GstSummary> summary(PeriodChoice? period) async => GstSummary.fromJson(await _api.get('/gst/summary', query: period?.query));

  @override
  Future<Uint8List> csv(PeriodChoice? period) => _api.getBytes('/gst/export.csv', query: period?.query);

  @override
  Future<Uint8List> gstr1(PeriodChoice? period) => _api.getBytes('/gst/gstr1.json', query: period?.query);

  @override
  Future<List<InvoiceRow>> invoices({int limit = 30}) async {
    final j = await _api.get('/invoices', query: {'limit': limit});
    return (j['invoices'] as List).map((e) => InvoiceRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<InvoiceRow> invoice(String id) async => InvoiceRow.fromJson(await _api.get('/invoices/$id'));

  @override
  Future<Uint8List> invoicePdf(String id) => _api.getBytes('/invoices/$id/pdf');
}

final gstRepositoryProvider = Provider<GstRepository>((ref) => HttpGstRepository(ref.watch(apiClientProvider)));

/// The period the GST screen is showing (null = this month).
final gstPeriodProvider = StateProvider.autoDispose<PeriodChoice?>((_) => null);
final gstPeriodsProvider = FutureProvider.autoDispose((ref) => ref.watch(gstRepositoryProvider).periods());
final gstSummaryProvider = FutureProvider.autoDispose((ref) => ref.watch(gstRepositoryProvider).summary(ref.watch(gstPeriodProvider)));
final invoicesProvider = FutureProvider.autoDispose((ref) => ref.watch(gstRepositoryProvider).invoices(limit: 20));
final invoiceProvider = FutureProvider.autoDispose.family<InvoiceRow, String>((ref, id) => ref.watch(gstRepositoryProvider).invoice(id));
