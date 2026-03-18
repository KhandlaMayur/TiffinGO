# Delivery Charge Implementation Guide

## Overview
This document explains the complete implementation of distance-based delivery charges in the TiffinGO app.

---

## How It Works

### 1. **Delivery Charge Calculation** ₹5 per km
- Distance is calculated using the **Haversine formula** (great-circle distance)
- Formula: `Delivery Charge = Distance (km) × ₹5/km`
- Example:
  - 2 km distance → ₹10
  - 5 km distance → ₹25
  - 10 km distance → ₹50

### 2. **Subscribers Get Free Delivery**
- Users with active subscriptions get **FREE delivery**
- Non-subscribers pay based on calculated distance

### 3. **Data Flow**

```
User Orders
    ↓
[PaymentDeliveryScreen]
    ↓
    Fetch seller's kitchen location from Firestore
    (Fallback to hardcoded locations if not found)
    ↓
    Get user's current location
    ↓
    Calculate distance using Haversine formula
    ↓
    Calculate delivery charge = distance × ₹5
    ↓
    Show delivery charge in Order Summary
    ↓
    Update OrderModel with:
    - deliveryCharge
    - distanceInKm
    - sellerLocation {latitude, longitude}
    ↓
[AdvancedDeliveryTrackingScreen]
    ↓
    Retrieve delivery charge from OrderModel
    ↓
    Use seller location to draw route from kitchen → user location
    ↓
    Display delivery charge with distance in tracking card
    ↓
    Show shortest route on map
```

---

## Implementation Details

### A. OrderModel Enhancement
**File**: `lib/models/order_model.dart`

New fields added:
```dart
final double deliveryCharge;              // Delivery charge in rupees
final double distanceInKm;                // Distance from seller to user in km
final Map<String, dynamic>? sellerLocation; // {latitude, longitude}
```

### B. Payment Delivery Screen
**File**: `lib/screens/payment_delivery_screen.dart`

**Key Methods:**
1. `_fetchServiceLocation()` - Fetches seller location from Firestore
2. `_calculateDistance()` - Calculates distance using Haversine formula
3. `_calculateDeliveryCharge()` - Returns `distance × ₹5`
4. `_getCurrentLocation()` - Gets user's current position
5. `_recalculateDeliveryCharge()` - Recalculates when both locations available

**Constants:**
```dart
static const double GST_RATE = 0.18;              // 18% GST
static const double PER_KM_CHARGE = 5.0;          // ₹5 per km
```

**Seller Location Priority (in _fetchServiceLocation):**
1. Try fetching from Firestore using `serviceId`
2. Try fetching from Firestore using `serviceName`
3. Fall back to hardcoded coordinates

**Hardcoded Locations (Fallback):**
```dart
'kathiyavadi': LatLng(22.2953, 70.8000)  // Trikon Baug, Rajkot
'nani': LatLng(22.2964, 70.7903)         // Yagnik Road, Rajkot
'rajwadi': LatLng(22.3248, 70.7720)      // Madhapar, Rajkot
'desi_rotalo': LatLng(22.34, 70.80)      // Greenland Chowk, Rajkot
```

**Order Summary Display:**
```
Meal Amount:        ₹100
GST (18%):          ₹18
Delivery Charge:    ₹30 (6 km)  ← Shows charge and distance
─────────────────────────────
Total Amount:       ₹148
```

### C. Advanced Delivery Tracking Screen
**File**: `lib/screens/advanced_delivery_tracking_screen.dart`

**Key Updates:**
1. Extracts `sellerLocation` from OrderModel in `initState()`
2. Uses seller location to determine kitchen coordinates
3. Displays delivery charge in bottom info card
4. Shows route from seller location → user location
5. Shows distance and delivery charge together

**Kitchen Selection Priority (in _selectedKitchen getter):**
1. **Use sellerLocation from OrderModel if available** ← NEW
2. Use serviceId-based matching
3. Use serviceName-based matching
4. Default to Kathiyavadi

**Bottom Card Display:**
```
Distance:    5.2 km
ETA:         15 minutes
Status:      Preparing
─────────────────────────
Service:     Kathiyavadi
Meal Type:   Veg
Meal Plan:   5 Days
Payment:     Cash on Delivery
Delivery:    ₹26 (5.2 km)  ← NEW: Shows charge with distance
```

---

## Firestore Setup Required

### Tiffin Services Collection
**Collection**: `tiffin_services`

**Required Fields for Each Document:**
```javascript
{
  id: "kathiyavadi",
  name: "Kathiyavadi Tiffin Service",
  latitude: 22.2953,           // ← IMPORTANT: Kitchen latitude
  longitude: 70.8000,          // ← IMPORTANT: Kitchen longitude
  address: "Trikon Baug, Rajkot",
  phone: "9876543210",
  rating: 4.5,
  ... (other fields)
}
```

**Steps to Update Firestore:**
1. Go to Firebase Console → Firestore Database
2. Open `tiffin_services` collection
3. For each service document, add/update:
   - `latitude` - Kitchen's GPS latitude
   - `longitude` - Kitchen's GPS longitude

---

## Key Features

### ✅ Implemented Features
1. ✅ Distance-based delivery charges (₹5/km)
2. ✅ Automatic location detection (user's current position)
3. ✅ Seller location fetched from Firestore
4. ✅ Fallback to hardcoded locations if Firestore missing
5. ✅ Free delivery for subscribers
6. ✅ Display delivery charge in payment screen
7. ✅ Display delivery charge in tracking screen
8. ✅ Show distance with delivery charge
9. ✅ Correct route from seller → user shown on map
10. ✅ Haversine formula for accurate distance calculation

### 🔍 Debugging

**Enable Debug Logs:**
Check Android Studio Logcat for these debug messages:
```
🔍 Fetching location for service: Kathiyavadi (ID: kathiyavadi)
✅ Found by serviceId: Lat=22.2953, Lng=70.8000
📍 Distance calculated: 5.2 km
💰 Delivery charge: ₹26 (5.2 km × ₹5/km)
✅ Seller location from order: (LatLng(22.2953, 70.8000))
✅ Route calculated: 5.2 km, 15 mins
```

### 🧪 Testing

**Test Case 1: Basic Order Flow**
1. Open app → Select Service → Place Order
2. Go to Payment Screen → Verify:
   - ✅ User location detected (GPS)
   - ✅ Seller location fetched
   - ✅ Distance calculated correctly
   - ✅ Delivery charge shown (distance × ₹5)
3. Complete payment
4. Go to Tracking Screen → Verify:
   - ✅ Route shown from seller → user
   - ✅ Delivery charge displayed
   - ✅ Distance shown with charge

**Test Case 2: Subscriber Flow**
1. Subscribe to a meal plan
2. Place order
3. Verify in Order Summary:
   - ✅ Delivery Charge shows "FREE (Subscribed)"
   - ✅ No delivery charge added to total

**Test Case 3: No Location Available**
1. Deny location permissions
2. Order processing should still work with fallback locations
3. Delivery charge should be ₹0 initially

---

## Files Modified

1. **lib/models/order_model.dart**
   - Added deliveryCharge, distanceInKm, sellerLocation fields
   - Updated toJson() and fromJson() methods

2. **lib/screens/payment_delivery_screen.dart**
   - Enhanced OrderModel creation in all 3 places (Track button, COD button, Online payment button)
   - Passes deliveryCharge, distanceInKm, sellerLocation to OrderModel

3. **lib/screens/advanced_delivery_tracking_screen.dart**
   - Added _sellerLocationFromOrder field
   - Updated initState() to extract sellerLocation from order
   - Updated _selectedKitchen getter to prioritize sellerLocation
   - Enhanced bottom card to display delivery charge with distance

---

## Troubleshooting

### Issue: Delivery charge showing 0
**Solution:**
- Check if Firestore has `latitude` and `longitude` fields for service
- If missing, hardcoded fallback locations will be used
- Check Logcat for "❌ No documents found" message

### Issue: Route not showing correctly
**Solution:**
- Verify user location permissions are granted
- Check if GPS is enabled on device
- Ensure TomTom API key is configured

### Issue: Wrong seller location used
**Solution:**
- Check if `sellerLocation` is being passed in OrderModel
- If not, verify payment screen correctly sets `_serviceLatitude` and `_serviceLongitude`
- Check hardcoded fallback location matches expected coordinates

---

## Formula Reference

**Haversine Distance Formula:**
```
a = sin²(Δφ/2) + cos(φ1) × cos(φ2) × sin²(Δλ/2)
c = 2 × atan2(√a, √(1-a))
d = R × c

Where:
- φ = latitude, λ = longitude (in radians)
- R = Earth's radius (6371 km)
- Δφ = difference in latitude
- Δλ = difference in longitude
- d = distance in kilometers
```

**Delivery Charge Formula:**
```
Delivery Charge (₹) = Distance (km) × Per KM Rate (₹5)

Example:
- 2 km × ₹5 = ₹10
- 5.2 km × ₹5 = ₹26
- 10 km × ₹5 = ₹50
```

---

## Next Steps

1. ✅ Update all seller documents in Firestore with `latitude` and `longitude`
2. ✅ Test the complete order flow
3. ✅ Verify delivery charges are calculated correctly
4. ✅ Monitor Firestore for missing location data
5. ✅ Consider adding delivery radius limits if needed
6. ✅ Consider adding surge pricing for peak hours (future enhancement)

