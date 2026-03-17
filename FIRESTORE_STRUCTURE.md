# Firestore Structure: tiffin_services Collection

## Visual Structure

```
firestore_database
└── tiffin_services/                    (Collection)
    ├── kathiyavadi/                    (Document)
    │   ├── id        : "kathiyavadi"
    │   ├── name      : "Kathiyavadi Tiffine Service"
    │   ├── latitude  : 23.1815
    │   ├── longitude : 72.6369
    │   ├── address   : "Trikon Baug, Ahmedabad"
    │   ├── phone     : "+91-9876543210"
    │   ├── description : "Authentic Kathiyawadi cuisine..."
    │   └── isActive  : true
    │
    ├── desi_rotalo/                    (Document)
    │   ├── id        : "desi_rotalo"
    │   ├── name      : "Desi Rotalo Tiffine Service"
    │   ├── latitude  : 23.1850
    │   ├── longitude : 72.6400
    │   ├── address   : "C.G. Road, Ahmedabad"
    │   ├── phone     : "+91-9876543211"
    │   ├── description : "Fresh rotis and traditional..."
    │   └── isActive  : true
    │
    ├── nani/                           (Document)
    │   ├── id        : "nani"
    │   ├── name      : "Nani Tiffine Service"
    │   ├── latitude  : 23.1780
    │   ├── longitude : 72.6350
    │   ├── address   : "Satellite Road, Ahmedabad"
    │   ├── phone     : "+91-9876543212"
    │   ├── description : "Home-style cooking with..."
    │   └── isActive  : true
    │
    └── rajwadi/                        (Document)
        ├── id        : "rajwadi"
        ├── name      : "Rajwadi Tiffine Service"
        ├── latitude  : 23.1950
        ├── longitude : 72.6450
        ├── address   : "S.G. Highway, Ahmedabad"
        ├── phone     : "+91-9876543213"
        ├── description : "Royal Rajasthani cuisine..."
        └── isActive  : true
```

---

## Raw JSON Format

If you want to copy-paste this into Firebase Console:

```json
{
  "tiffin_services": {
    "kathiyavadi": {
      "id": "kathiyavadi",
      "name": "Kathiyavadi Tiffine Service",
      "latitude": 23.1815,
      "longitude": 72.6369,
      "address": "Trikon Baug, Ahmedabad",
      "phone": "+91-9876543210",
      "description": "Authentic Kathiyawadi cuisine with traditional flavors",
      "isActive": true
    },
    "desi_rotalo": {
      "id": "desi_rotalo",
      "name": "Desi Rotalo Tiffine Service",
      "latitude": 23.1850,
      "longitude": 72.6400,
      "address": "C.G. Road, Ahmedabad",
      "phone": "+91-9876543211",
      "description": "Fresh rotis and traditional Gujarati dishes",
      "isActive": true
    },
    "nani": {
      "id": "nani",
      "name": "Nani Tiffine Service",
      "latitude": 23.1780,
      "longitude": 72.6350,
      "address": "Satellite Road, Ahmedabad",
      "phone": "+91-9876543212",
      "description": "Home-style cooking with grandmother's recipes",
      "isActive": true
    },
    "rajwadi": {
      "id": "rajwadi",
      "name": "Rajwadi Tiffine Service",
      "latitude": 23.1950,
      "longitude": 72.6450,
      "address": "S.G. Highway, Ahmedabad",
      "phone": "+91-9876543213",
      "description": "Royal Rajasthani cuisine with rich flavors",
      "isActive": true
    }
  }
}
```

---

## Important Notes

1. **Collection Name**: Must be exactly `tiffin_services` (lowercase)
2. **Document IDs**: Must match service IDs:
   - `kathiyavadi`
   - `desi_rotalo`
   - `nani`
   - `rajwadi`
3. **Field Names**: Case-sensitive (use lowercase exactly as shown)
4. **Data Types**:
   - `latitude` = Number (not string)
   - `longitude` = Number (not string)
   - `isActive` = Boolean
   - Everything else = String

---

## Coordinates Accuracy

All coordinates are for Ahmedabad city locations:

| Service | Location | Latitude | Longitude | Distance from Trikon Baug |
|---------|----------|----------|-----------|---------------------------|
| Kathiyavadi | Trikon Baug | 23.1815 | 72.6369 | 0 km (reference) |
| Desi Rotalo | C.G. Road | 23.1850 | 72.6400 | ~4.5 km |
| Nani | Satellite Road | 23.1780 | 72.6350 | ~4 km |
| Rajwadi | S.G. Highway | 23.1950 | 72.6450 | ~12 km |

---

## App Integration

When order is placed:

1. **serviceId** from order = document ID in Firestore
2. **Service document** is fetched → gets latitude/longitude
3. **User location** is detected → gets current coordinates
4. **Distance** is calculated using Haversine formula
5. **Delivery charge** = distance × ₹5 per km

---

## Console View (After Adding)

In Firebase Console → Firestore, you should see:

```
tiffin_services (collection)
├── doc → kathiyavadi
│   Document ID: kathiyavadi
│   Fields shown with values
├── doc → desi_rotalo
│   Document ID: desi_rotalo
│   Fields shown with values
├── doc → nani
│   Document ID: nani
│   Fields shown with values
└── doc → rajwadi
    Document ID: rajwadi
    Fields shown with values
```

---

## Sample Order Flow

```
User places order from Kathiyavadi
│
├─ serviceId = "kathiyavadi"
├─ serviceName = "Kathiyavadi Tiffine Service"
│
↓
App fetches from Firestore:
  Collection: tiffin_services
  Document: kathiyavadi
  Gets: latitude=23.1815, longitude=72.6369
│
↓
User grants location permission
│
│─ User location: 23.1850, 72.6300
│
↓
Calculate distance:
  From: 23.1815, 72.6369 (Kitchen)
  To:   23.1850, 72.6300 (User)
  Distance: 5.9 km
│
↓
Calculate delivery charge:
  5.9 km × ₹5/km = ₹29.50
│
↓
Display in Order Summary:
  Delivery Charge: ₹29.50 (5.9 km)
```

---

## Testing Checklist

After adding to Firestore:

- [ ] Can you see collection `tiffin_services` in Console?
- [ ] Can you see 4 documents in the collection?
- [ ] Each document has field `latitude` (type: Number)?
- [ ] Each document has field `longitude` (type: Number)?
- [ ] Numbers are not in quotes (correct: `23.1815`, wrong: `"23.1815"`)?
- [ ] Document IDs match service IDs exactly?

If all ✅, delivery charges are ready to go!
