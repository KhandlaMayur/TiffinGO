# Delivery Charge Implementation - Quick Reference

## ✅ Changes Made

### 1. **OrderModel** (`lib/models/order_model.dart`)
```dart
Added 3 new fields:
✅ deliveryCharge: double      // ₹5 × km
✅ distanceInKm: double        // Distance calculated
✅ sellerLocation: Map?        // {latitude, longitude}
```

### 2. **Payment Screen** (`lib/screens/payment_delivery_screen.dart`)
```dart
Updated 3 OrderModel creations to include:
✅ deliveryCharge: hasActiveSubscription ? 0.0 : _deliveryCharge
✅ distanceInKm: _distanceInKm
✅ sellerLocation: {latitude, longitude}
```

### 3. **Tracking Screen** (`lib/screens/advanced_delivery_tracking_screen.dart`)
```dart
✅ Extract sellerLocation from order in initState()
✅ Use seller location to determine kitchen coordinates
✅ Display delivery charge + distance in bottom card
✅ Show correct route from seller → user
```

---

## 🎯 How It Works

### User Places Order
```
User selects meal → Amount = ₹100
```

### Payment Screen
```
1. Fetch seller's kitchen location from Firestore
   OR use fallback hardcoded location
   
2. Get user's current GPS location
   
3. Calculate distance = Seller location → User location (Haversine formula)
   
4. Calculate delivery charge = distance × ₹5/km
   
5. Display:
   Meal:        ₹100
   GST (18%):   ₹18
   Delivery:    ₹30 (6 km)  ← NEW!
   ─────────────────────────
   Total:       ₹148
   
6. Save order with deliveryCharge, distanceInKm, sellerLocation
```

### Tracking Screen
```
1. Retrieve delivery charge from OrderModel
   
2. Use seller location to draw route on map
   
3. Display:
   ✅ Distance: 6 km
   ✅ Delivery: ₹30 (6 km)
   ✅ Route: Kitchen → Your Location (on map)
```

---

## 🔑 Key Features

| Feature | Status | Details |
|---------|--------|---------|
| Distance Calculation | ✅ | Haversine formula (accurate) |
| Delivery Charge | ✅ | ₹5 per km |
| Subscription Free Delivery | ✅ | Active subscribers pay ₹0 |
| Seller Location from Firestore | ✅ | Priority over hardcoded values |
| Fallback Locations | ✅ | 4 default locations if Firestore missing |
| Order Summary Display | ✅ | Shows charge + distance |
| Tracking Display | ✅ | Shows charge + distance + route |
| Correct Route on Map | ✅ | From seller → user location |

---

## 📍 Seller Locations (Fallback)

If Firestore doesn't have location data, these defaults are used:

| Service | Latitude | Longitude | Location |
|---------|----------|-----------|----------|
| Kathiyavadi | 22.2953 | 70.8000 | Trikon Baug, Rajkot |
| Nani | 22.2964 | 70.7903 | Yagnik Road, Rajkot |
| Rajwadi | 22.3248 | 70.7720 | Madhapar, Rajkot |
| Desi Roti | 22.34 | 70.80 | Greenland Chowk, Rajkot |

---

## 🧪 Testing Checklist

### ✅ Order Placement Test
- [ ] User location detected (GPS)
- [ ] Seller location fetched from Firestore
- [ ] Distance calculated correctly
- [ ] Delivery charge = distance × 5
- [ ] Order Summary shows delivery charge

### ✅ Tracking Test
- [ ] Tracking screen opens
- [ ] Seller location matches kitchen coordinates
- [ ] Route drawn from seller → user
- [ ] Delivery charge displayed
- [ ] Distance shown with charge

### ✅ Subscriber Test
- [ ] Active subscription = "FREE" delivery
- [ ] Total amount doesn't include delivery charge
- [ ] Tracking still shows delivery structure

### ✅ Permission Denial Test
- [ ] If location denied, use fallback locations
- [ ] Order still completes
- [ ] Delivery charge = 0 (location not available)

---

## 🔧 Configuration

### Required Firestore Setup
Each tiffin_services document must have:
```javascript
{
  id: "kathiyavadi",
  name: "Kathiyavadi",
  latitude: 22.2953,      // REQUIRED
  longitude: 70.8000,     // REQUIRED
  // ... other fields
}
```

### Constants in Code
```dart
PER_KM_CHARGE = 5.0;    // ₹5 per km
GST_RATE = 0.18;        // 18% GST
```

---

## 📊 Delivery Charge Examples

| Distance | Calculation | Charge |
|----------|-------------|--------|
| 1 km | 1 × 5 | ₹5 |
| 2 km | 2 × 5 | ₹10 |
| 3.5 km | 3.5 × 5 | ₹17.50 |
| 5 km | 5 × 5 | ₹25 |
| 10 km | 10 × 5 | ₹50 |

---

## 🐛 Debug Tips

### Check Logcat for:
```
🔍 Fetching location for service: [Service Name]
✅ Found by serviceId: Lat=X, Lng=Y
📍 Distance calculated: X km
💰 Delivery charge: ₹X (X km × ₹5/km)
✅ Seller location from order: (LatLng(...))
```

### Common Issues & Solutions:

| Issue | Solution |
|-------|----------|
| Delivery = 0 but should be > 0 | Check if location permissions granted |
| Wrong seller location | Verify Firestore has latitude/longitude |
| Route not showing | Check GPS is enabled on device |
| Wrong distance | Check both locations are fetched correctly |

---

## 📁 Files Modified

1. `lib/models/order_model.dart` - Added 3 fields
2. `lib/screens/payment_delivery_screen.dart` - Pass delivery data
3. `lib/screens/advanced_delivery_tracking_screen.dart` - Display delivery data

---

## 🎯 Next Steps

1. Deploy code
2. Update Firestore sellers with latitude/longitude
3. Test complete flow
4. Monitor for any missing Firestore data
5. Adjust ₹5/km rate if needed

---

## 💡 Future Enhancements

- [ ] Delivery radius limits
- [ ] Surge pricing for peak hours
- [ ] Multiple delivery options (express, standard)
- [ ] Restaurant-specific delivery rates
- [ ] Delivery tracking in real-time

