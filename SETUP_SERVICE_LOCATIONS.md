# How to Add Tiffin Service Locations for Distance-Based Delivery Charges

The delivery charge system now calculates based on actual distance from each kitchen to user location. You need to add location coordinates for each tiffin service.

## Option 1: Firebase Console (Easiest)

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your project (TiffinGO)
3. Go to Firestore Database

### Step 2: Create Collection
1. Click "Create collection"
2. Collection ID: `tiffin_services`
3. Click "Next"

### Step 3: Add Documents
For each tiffin service, add a document:

**Document ID**: `kathiyavadi` (use your service ID)

**Fields**:
- `id` (string): `kathiyavadi`
- `name` (string): `Kathiyavadi Tiffine Service`
- `latitude` (number): `23.1815`
- `longitude` (number): `72.6369`
- `address` (string): `Trikon Baug, Ahmedabad`
- `phone` (string): `+91-XXXXXXXXXX`
- `description` (string): `Traditional Kathiyavadi tiffin service`
- `isActive` (boolean): `true`

### Repeat for Other Services:
```
Document: desi_rotalo
- name: "Desi Rotalo Service"
- latitude: 23.1850
- longitude: 72.6400
- address: "C.G. Road, Ahmedabad"

Document: north_indian
- name: "North Indian Tiffine Service"
- latitude: 23.1780
- longitude: 72.6350
- address: "Satellite Road, Ahmedabad"
```

---

## Option 2: Using Dart Code (Programmatic)

### Step 1: Run Setup Function
Add this to your app's initialization (e.g., in `main.dart` or first-time setup screen):

```dart
import 'package:your_app/setup/firestore_setup.dart';

void main() {
  // ... Firebase initialization ...
  
  // Setup tiffin service locations (run once)
  FirestoreSetup.setupTiffinServiceLocations();
  
  runApp(const MyApp());
}
```

Or create a Settings/Admin page with a button:

```dart
ElevatedButton(
  onPressed: () async {
    await FirestoreSetup.setupTiffinServiceLocations();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service locations updated!'))
    );
  },
  child: const Text('Setup Service Locations'),
)
```

### Step 2: Debug
To see if services are properly set up:

```dart
// Add this in a debug method
FirestoreSetup.debugPrintServiceLocations();
```

Check the console output for all available services.

---

## Finding Coordinates for Your Locations

### Method 1: Google Maps (Easiest)
1. Open https://maps.google.com
2. Search for your tiffin service location
3. Right-click on the location
4. Coordinates appear at top - click to copy
5. Format: `23.1815, 72.6369`

**Example for Trikon Baug:**
- Open Google Maps
- Search "Trikon Baug, Ahmedabad"
- Right-click on the location pin
- You'll see coordinates like: `23.18152°N, 72.63686°E`
- Use: latitude: 23.18152, longitude: 72.63686

### Method 2: Online Coordinates Tool
- Use https://www.latlong.net/
- Search for location → Copy coordinates

### Common Ahmedabad Service Locations:
| Location | Latitude | Longitude | Notes |
|----------|----------|-----------|-------|
| Trikon Baug | 23.1815 | 72.6369 | Kathiyavadi kitchen |
| C.G. Road | 23.1850 | 72.6400 | Central location |
| Satellite Road | 23.1780 | 72.6350 | South |
| S.G. Highway | 23.1950 | 72.6450 | North |

---

## Testing Distance Calculation

After adding service locations:

1. **Open App** → Order from Kathiyavadi
2. **On Payment Screen** → See Order Summary
3. **Grant Location Permission** → Allow current location
4. **Check Delivery Charge** → Should show: `₹X.XX (Y.Y km)`

### Example:
```
Meal Amount:        ₹100.00
GST (18%):          ₹18.00
Delivery Charge:    ₹75.00 (15.0 km)  ← Distance × ₹5
─────────────────────────────
Total Amount:       ₹193.00
```

---

## Dashboard Verification

### Check Firestore Collection:
```
• Go to Firebase Console
• Firestore Database
• Look for "tiffin_services" collection
• Each service should show ID, name, latitude, longitude
```

### Debug Logs (When Running App):
```
🔍 Fetching location for service: Kathiyavadi Tiffine Service (ID: kathiyavadi)
✅ Found by serviceId: Lat=23.1815, Lng=72.6369
📍 Requesting user location...
✅ User location: 23.1850, 72.6300
📍 Distance calculated: 5.9 km
💰 Delivery charge: ₹29.5 (5.9 km × ₹5/km)
```

---

## Troubleshooting

### Problem: Delivery Charge Shows 0
**Possible Causes:**
- [ ] Service location not in Firestore
- [ ] User hasn't granted location permission
- [ ] Service ID doesn't match in code and Firestore

**Solution:**
1. Check Firestore → `tiffin_services` collection
2. Verify document ID matches `serviceId` in order
3. Ensure location coordinates exist (latitude/longitude fields)

### Problem: Wrong Distance Calculated
**Check:**
- [ ] Are kitchen coordinates correct?
- [ ] Are user coordinates showing in debug logs?
- [ ] Is it measuring km correctly?

**Debug:**
```dart
// In console logs look for:
✅ Found by serviceId: Lat=23.1815, Lng=72.6369
✅ User location: 23.1850, 72.6300
📍 Distance calculated: 5.9 km
```

### Problem: Service Location Not Found
**Error in Console:**
```
❌ Document not found for serviceId: kathiyavadi
❌ No documents found for service name: Kathiyavadi Tiffine Service
```

**Solution:**
1. Go to Firebase Console
2. Check collection name: exactly `tiffin_services` (lowercase)
3. Check document ID: exactly matches `serviceId` (case-sensitive)
4. Verify fields: `latitude` and `longitude` (exact names)

---

## Example Firestore Structure

```
firestore_database/
└── tiffin_services/ (collection)
    ├── kathiyavadi/ (document)
    │   ├── id: "kathiyavadi"
    │   ├── name: "Kathiyavadi Tiffine Service"
    │   ├── latitude: 23.1815 (number)
    │   ├── longitude: 72.6369 (number)
    │   ├── address: "Trikon Baug, Ahmedabad"
    │   └── isActive: true
    │
    ├── desi_rotalo/ (document)
    │   ├── id: "desi_rotalo"
    │   ├── name: "Desi Rotalo Service"
    │   ├── latitude: 23.1850
    │   ├── longitude: 72.6400
    │   └── ...
    │
    └── north_indian/ (document)
        ├── id: "north_indian"
        ├── name: "North Indian Tiffine Service"
        ├── latitude: 23.1780
        └── ...
```

---

## Support

**When testing:**
- Look at Flutter console for debug messages (🔍, ✅, ❌, 📍, 💰)
- These indicate whether service location was found and distance calculated
- If you see ❌ messages, check Firestore database first

**Quick Checklist:**
- ✅ Collection created: `tiffin_services`
- ✅ Documents with proper IDs: `kathiyavadi`, `desi_rotalo`, etc.
- ✅ Fields: `id`, `name`, `latitude`, `longitude`, `address`
- ✅ Latitude/Longitude are numbers (not strings)
- ✅ Coordinates are valid (-90 to 90 for lat, -180 to 180 for lng)
