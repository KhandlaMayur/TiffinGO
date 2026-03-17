# 🚀 QUICK START: Add Service Locations for Delivery Charges

## ⚡ TL;DR - In 5 Minutes

### What You Need To Do:
1. Open Firebase Console
2. Go to Firestore → Create collection: `tiffin_services`
3. Add 4 documents (one for each service) with location coordinates
4. App will automatically calculate delivery charges based on distance

---

## 📍 Step 1: Open Firebase Console

1. Go to: https://console.firebase.google.com
2. Select your project: **TiffinGO**
3. Click: **Firestore Database** (left sidebar)

---

## 📋 Step 2: Create Collection

1. Click: **"Create collection"**
2. Collection ID: **`tiffin_services`** (exactly as shown)
3. Click: **"Next"**

---

## 📝 Step 3: Add Service Locations

### Service 1: Kathiyavadi (Trikon Baug) ✅

**Document ID**: `kathiyavadi`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `kathiyavadi` |
| `name` | String | `Kathiyavadi Tiffine Service` |
| `latitude` | Number | `23.1815` |
| `longitude` | Number | `72.6369` |
| `address` | String | `Trikon Baug, Ahmedabad` |
| `phone` | String | `+91-9876543210` |
| `description` | String | `Authentic Kathiyawadi cuisine with traditional flavors` |
| `isActive` | Boolean | `true` |

### Service 2: Desi Rotalo (C.G. Road) ✅

**Document ID**: `desi_rotalo`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `desi_rotalo` |
| `name` | String | `Desi Rotalo Tiffine Service` |
| `latitude` | Number | `23.1850` |
| `longitude` | Number | `72.6400` |
| `address` | String | `C.G. Road, Ahmedabad` |
| `phone` | String | `+91-9876543211` |
| `description` | String | `Fresh rotis and traditional Gujarati dishes` |
| `isActive` | Boolean | `true` |

### Service 3: Nani (Satellite Road) ✅

**Document ID**: `nani`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `nani` |
| `name` | String | `Nani Tiffine Service` |
| `latitude` | Number | `23.1780` |
| `longitude` | Number | `72.6350` |
| `address` | String | `Satellite Road, Ahmedabad` |
| `phone` | String | `+91-9876543212` |
| `description` | String | `Home-style cooking with grandmother's recipes` |
| `isActive` | Boolean | `true` |

### Service 4: Rajwadi (S.G. Highway) ✅

**Document ID**: `rajwadi`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `rajwadi` |
| `name` | String | `Rajwadi Tiffine Service` |
| `latitude` | Number | `23.1950` |
| `longitude` | Number | `72.6450` |
| `address` | String | `S.G. Highway, Ahmedabad` |
| `phone` | String | `+91-9876543213` |
| `description` | String | `Royal Rajasthani cuisine with rich flavors` |
| `isActive` | Boolean | `true` |

---

## 🧪 Step 4: Testing

1. **Install/Run App** on your phone
2. **Go to Payment & Delivery Screen** after placing order
3. **Grant Location Permission** when asked
4. **Check Order Summary**
   - Should show: `Delivery Charge: ₹X.XX (Y km)`
   - Example: `₹75.00 (15.0 km)`

### Debug Output (In Console):
```
🔍 Fetching location for service: Kathiyavadi Tiffine Service (ID: kathiyavadi)
✅ Found by serviceId: Lat=23.1815, Lng=72.6369
📍 Requesting user location...
✅ User location: 23.1850, 72.6300
✅ Service location available, calculating distance...
📍 Distance calculated: 5.9 km
💰 Delivery charge: ₹29.5 (5.9 km × ₹5/km)
```

---

## ❓ Troubleshooting

### Issue: Delivery Charge Shows ₹0
**Cause**: Service location not in Firestore

**Fix**:
- [ ] Go to Firestore Console
- [ ] Check collection: `tiffin_services` exists
- [ ] Check all 4 documents are there
- [ ] Verify document IDs are exactly: `kathiyavadi`, `desi_rotalo`, `nani`, `rajwadi`
- [ ] Verify all fields match the examples above

### Issue: Distance Shows Wrong
**Cause**: Coordinates might be wrong

**Fix**:
1. Open Google Maps: https://maps.google.com
2. Search for "Trikon Baug, Ahmedabad"
3. Right-click on the location pin
4. Copy the coordinates shown
5. Compare with the coordinates in Firestore
6. Update if different

### Issue: "Service location not found" in Debug
**Check**:
- Collection name is exactly: `tiffin_services` (lowercase)
- Document ID matches: `kathiyavadi`, `desi_rotalo`, etc.
- All fields are spelled correctly (`latitude`, `longitude`)
- Numbers are stored as **Number** type, not String

---

## 📊 How It Works

```
User Orders from Kitchen → App Gets User's Location
                          ↓
                    App Fetches Kitchen Location 
                          from Firestore
                          ↓
                    Calculates Distance Using GPS
                          ↓
                    Delivery Charge = Distance × ₹5/km
                          ↓
                    Shows in Order Summary
```

### Calculation Example:
```
Kitchen (Trikon Baug):   23.1815°, 72.6369°
User Location:           23.1850°, 72.6300°
Distance:                5.9 km
Delivery Charge:         5.9 × ₹5 = ₹29.50
```

---

## 💡 Pro Tips

### To Update Coordinates:
1. Go to Google Maps
2. Search location
3. Right-click → coordinates auto-copy
4. Format: `23.1815, 72.6369`
5. Split: Latitude = 23.1815, Longitude = 72.6369

### Testing Different Distances:
1. Use Mock Location app to test without traveling
2. Try ordering from different services
3. Check console (flutter logs) to see calculations

### For Future Services:
Just add new document with:
- Document ID (service ID)
- Name, latitude, longitude
- Rest of fields

---

## ✅ Verification Checklist

- [ ] Collection name: `tiffin_services` ✓
- [ ] Document IDs: `kathiyavadi`, `desi_rotalo`, `nani`, `rajwadi` ✓
- [ ] All fields present: `id`, `name`, `latitude`, `longitude` ✓
- [ ] Latitude/Longitude are **Numbers** (not text) ✓
- [ ] Values match the table above ✓
- [ ] App shows delivery charges in order summary ✓
- [ ] Distance displays correctly ✓

---

## 🆘 Need Help?

Check debug logs for messages like:
- ✅ `Found by serviceId` → Location found and working
- ❌ `Document not found` → Service location missing in Firestore
- 📍 `Distance calculated` → Calculation successful

**All debug messages help identify the exact issue!**
