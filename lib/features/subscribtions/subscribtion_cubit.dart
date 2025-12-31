/* Checks if user is pro or not */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharma_box/features/subscribtions/revenuecat_service.dart';
import 'package:pharma_box/features/subscribtions/subscribtion_state.dart';
import 'package:pharma_box/include/ble_functions.dart';

class SubscribtionCubit extends Cubit<SubscribtionState> {
  SubscribtionCubit() : super(SubscribtionInitial());

  Future<void> checkProStatus() async {
    emit(SubscribtionLoading());
    try {
      final isPro = await RevenuecatService.isProUser();
      emit(SubscribtionLoaded(isPro));
      logger.i('✅ Stato pro verificato: $isPro');
    } catch (e) {
      emit(SubscribtionError('Errore nel controllo dello stato pro: $e'));
      logger.e('❌ Errore nel controllo dello stato pro: $e');
    }
  }
}
