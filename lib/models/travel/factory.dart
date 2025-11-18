
import 'base_travel.dart';
import 'flight_item.dart';
import 'train_item.dart';
import 'transfer_item.dart';
import 'rental_car_item.dart';

TravelItem travelItemFromMap(Map<String, dynamic> map) {
  switch (map['type']) {
    case 'flight':
      return FlightItem.fromMap(map);
    case 'train':
      return TrainItem.fromMap(map);
    case 'transfer':
      return TransferItem.fromMap(map);
    case 'rentalCar':
      return RentalCarItem.fromMap(map);
    default:
      throw ArgumentError('Unknown travel item type: ${map['type']}');
  }
}
