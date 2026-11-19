import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geocoding_service.dart';
import '../data/place_repository.dart';
import '../domain/place.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) => PlaceRepository());
final geocodingProvider = Provider<GeocodingService>((ref) => GeocodingService());

/// Local de um rolê (pelo `plans.lugar_final_id`).
final placeProvider = FutureProvider.autoDispose.family<Place?, String>((ref, id) {
  return ref.watch(placeRepositoryProvider).getPlace(id);
});
