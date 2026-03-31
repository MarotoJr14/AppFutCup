import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lineup_model.dart';
import '../repositories/lineup_repository.dart';

final lineupRepositoryProvider = Provider((_) => LineupRepository());

final matchLineupsProvider = FutureProvider.family<List<LineupModel>, int>((ref, matchId) {
  return ref.read(lineupRepositoryProvider).getByMatch(matchId);
});
