# Firestore Setup Guide for Tiffin Service Locations

## Required Collection: `tiffin_services`

To enable dynamic delivery charge calculation based on distance, you need to add location coordinates to your tiffin services in Firestore.

### Collection Path
```
/tiffin_services/{serviceId}
```

### Document Structure

Each tiffin service document should have the following fields:

```json
{
  "id": "kathiyavadi",
  "name": "Kathiyavadi Tiffine Service",
  "latitude": 23.1815,
  "longitude": 72.6369,
  "address": "Trikon Baug, Ahmedabad",
  "description": "Traditional Kathiyavadi tiffin service",
  ...otherFields
}
```

### Example Data for Ahmedabad Services

**Kathiyavadi Tiffine Service (Trikon Baug)**
```json
{
  "id": "kathiyavadi",
  "name": "Kathiyavadi Tiffine Service",
  "latitude": 23.1815,
  "longitude": 72.6369,
  "address": "Trikon Baug, Ahmedabad",
  "phone": "+91-XXXXXXXXXX",
  "isActive": true
}
```

**Desi Rotalo Service**
```json
{
  "id": "desi_rotalo",
  "name": "Desi Rotalo Service",
  "latitude": 23.1850,
  "longitude": 72.6400,
  "address": "C.G. Road, Ahmedabad",
  "phone": "+91-XXXXXXXXXX",
  "isActive": true
}
```

**North Indian Service**
```json
{
  "id": "north_indian",
  "name": "North Indian Tiffine Service",
  "latitude": 23.1780,
  "longitude": 72.6350,
  "address": "Satellite Road, Ahmedabad",
  "phone": "+91-XXXXXXXXXX",
  "isActive": true
}
```

## How It Works

1. **Service Location Fetch**: When a user places an order, the app fetches the service location from Firestore
2. **Distance Calculation**: Uses Haversine formula to calculate actual distance from kitchen to user
3. **Delivery Charge**: Applies ₹5 per kilometer (no base charge)
4. **Updated UI**: Shows distance in order summary (e.g., "₹75.00 (15.0 km)")

## Steps to Add Location Data

### Via Firebase Console:
1. Go to Firestore Database
2. Create collection: `tiffin_services` (if not exists)
3. Add document with serviceId as document ID
4. Add fields: `id`, `name`, `latitude`, `longitude`, `address`, etc.

### Via Flutter Code (One-time setup):
```dart
// Add this in your app initialization or create a setup screen
Future<void> setupTiffinServiceLocations() async {
  final db = FirebaseFirestore.instance;
  
  final services = [
    {
      'id': 'kathiyavadi',
      'name': 'Kathiyavadi Tiffine Service',
      'latitude': 23.1815,
      'longitude': 72.6369,
      'address': 'Trikon Baug, Ahmedabad',
    },
    // Add more services...
  ];
  
  for (var service in services) {
    await db.collection('tiffin_services').doc(service['id']).set(service);
  }
}
```

## Finding Coordinates

To get latitude and longitude for your tiffin services:

1. **Google Maps**: Right-click location → coords automatically copied
2. **Online Tools**: https://maps.google.com → Search address → Get coords from URL
3. **Coordinates Format**: 
   - Latitude: -90 to +90 (North/South)
   - Longitude: -180 to +180 (East/West)

## Example: Trikon Baug, Ahmedabad
- **Address**: Trikon Baug, Ahmedabad
- **Latitude**: 23.1815
- **Longitude**: 72.6369
- **Delivery Charge Formula**: ₹ = distance_in_km × 5

## Important Notes

- ✅ Each service can have different location
- ✅ Delivery charge only applies to non-subscribers
- ✅ Subscribers get free delivery
- ✅ Formula: Distance × ₹5/km (no base charge)
- ✅ Distance is calculated from kitchen to user's current location
- ✅ If service location not found in Firestore, no delivery charge is applied

## Troubleshooting

**Issue**: Delivery charge still shows 0
- **Check**: Is service location stored in Firestore?
- **Check**: Are coordinates valid (latitude -90 to 90, longitude -180 to 180)?
- **Check**: Is user's location permission enabled?

**Issue**: Distance seems incorrect
- **Check**: Are kitchen coordinates correct?
- **Check**: Is user location updated?

## Testing

Once coordinates are added, test by:
1. Order from Kathiyavadi service
2. Grant location permission
3. Check order summary → Delivery Charge should show calculated amount with distance
