import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../home/data/home_repository.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../khata/data/khata_repository.dart';
import '../../stock/data/stock_repository.dart';
import '../data/bill_repository.dart';
import '../domain/bill_models.dart';

enum BillPhase { pick, reading, draft, saving, saved }

class BillState {
  const BillState({this.phase = BillPhase.pick, this.photo, this.sampleKey, this.draft, this.choices = const [], this.saved, this.error});

  final BillPhase phase;
  final BillPhoto? photo;
  final String? sampleKey;
  final BillDraft? draft;

  /// Per bill line, the material the user confirmed (null = skip).
  final List<String?> choices;
  final BillSaved? saved;
  final ApiException? error;

  bool get canSave => draft != null && choices.any((c) => c != null) && phase == BillPhase.draft;

  BillState copyWith({BillPhase? phase, BillPhoto? photo, String? sampleKey, BillDraft? draft, List<String?>? choices, BillSaved? saved, ApiException? error, bool clearError = false}) => BillState(
        phase: phase ?? this.phase,
        photo: photo ?? this.photo,
        sampleKey: sampleKey ?? this.sampleKey,
        draft: draft ?? this.draft,
        choices: choices ?? this.choices,
        saved: saved ?? this.saved,
        error: clearError ? null : error ?? this.error,
      );
}

/// Photo → read → check → confirm. Nothing reaches the books until the user says yes (RULES B2).
class BillController extends AutoDisposeNotifier<BillState> {
  @override
  BillState build() => const BillState();

  BillRepository get _repo => ref.read(billRepositoryProvider);

  Future<void> readPhoto(BillPhoto photo) =>
      _read(BillState(phase: BillPhase.reading, photo: photo), () => _repo.scanPhoto(photo));

  Future<void> readSample(String key) =>
      _read(BillState(phase: BillPhase.reading, sampleKey: key), () => _repo.scanSample(key));

  Future<void> _read(BillState start, Future<BillDraft> Function() scan) async {
    state = start;
    try {
      final draft = await scan();
      state = state.copyWith(
        phase: BillPhase.draft,
        draft: draft,
        choices: [for (final l in draft.lines) l.materialId.isEmpty ? null : l.materialId],
      );
    } catch (e) {
      state = state.copyWith(phase: BillPhase.pick, error: ApiException.from(e));
    }
  }

  void choose(int line, String? materialId) {
    final next = [...state.choices]..[line] = materialId;
    state = state.copyWith(choices: next);
  }

  Future<void> save() async {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(phase: BillPhase.saving, clearError: true);
    try {
      final saved = await _repo.confirm(draft.scanId, state.choices);
      state = state.copyWith(phase: BillPhase.saved, saved: saved);
      ref
        ..invalidate(homeProvider)
        ..invalidate(flowProvider)
        ..invalidate(materialsProvider)
        ..invalidate(khataPageProvider);
    } catch (e) {
      state = state.copyWith(phase: BillPhase.draft, error: ApiException.from(e));
    }
  }

  void reset() => state = const BillState();
}

final billControllerProvider = NotifierProvider.autoDispose<BillController, BillState>(BillController.new);
