import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/tenancy_model.dart';
import '../data/tenancy_repository.dart';

final tenancyRepositoryProvider = Provider((ref) => TenancyRepository());

final tenancyListProvider =
    StateNotifierProvider<TenancyListNotifier, List<TenancyRecord>>((ref) {
  return TenancyListNotifier(ref.watch(tenancyRepositoryProvider));
});

final tenancyByPropertyIdProvider =
    Provider.family<TenancyRecord?, String>((ref, propertyId) {
  final tenancies = ref.watch(tenancyListProvider);
  try {
    return tenancies.firstWhere((t) => t.propertyId == propertyId);
  } catch (_) {
    return null;
  }
});

class TenancyListNotifier extends StateNotifier<List<TenancyRecord>> {
  final TenancyRepository _repo;
  static const _uuid = Uuid();

  TenancyListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<TenancyRecord> save({
    String? existingId,
    required String propertyId,
    required double monthlyRent,
    required double securityDeposit,
    required DateTime tenancyStartDate,
    DateTime? tenancyEndDate,
    required String landlordName,
    required String landlordPhone,
    String? brokerName,
    String? brokerPhone,
    String? notes,
  }) async {
    final now = DateTime.now();
    final tenancy = TenancyRecord(
      id: existingId ?? _uuid.v4(),
      propertyId: propertyId,
      monthlyRent: monthlyRent,
      securityDeposit: securityDeposit,
      tenancyStartDate: tenancyStartDate,
      tenancyEndDate: tenancyEndDate,
      landlordName: landlordName,
      landlordPhone: landlordPhone,
      brokerName: brokerName,
      brokerPhone: brokerPhone,
      notes: notes,
      createdAt: existingId != null
          ? (state.where((t) => t.id == existingId).firstOrNull?.createdAt ?? now)
          : now,
      updatedAt: now,
    );
    await _repo.save(tenancy);
    _load();
    return tenancy;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }
}
