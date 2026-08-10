# Phytivra-AI API Documentation

## 5.1 Overview

The Phytivra-AI backend provides REST APIs for managing crop, disease, pesticide, recommendation, and crop-leaf image data. All APIs use HTTP methods and return responses in JSON format.

**Base URL:**

```text
http://127.0.0.1:8000/api/
```

All API responses are returned in JSON format unless otherwise specified.

---

# 5.2 Crop APIs

## 5.2.1 Get Crop List

### Endpoint URL

```text
GET /api/crops/
```

### Full URL

```text
http://127.0.0.1:8000/api/crops/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns a list of all crops available in the database.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response Format:**

```json
[
    {
        "id": 1,
        "name": "Tomato",
        "scientific_name": "Solanum lycopersicum",
        "description": "Tomato is an important vegetable crop grown widely in tropical, subtropical, and temperate regions.",
        "image": "http://127.0.0.1:8000/media/crop_images/tomato.jpg"
    },
    {
        "id": 2,
        "name": "Potato",
        "scientific_name": "Solanum tuberosum",
        "description": "Potato is a major food crop cultivated for its underground tubers.",
        "image": "http://127.0.0.1:8000/media/crop_images/potato.jpg"
    }
]
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Crop list retrieved successfully |
| 500 | Internal server error |

---

## 5.2.2 Get Crop Details

### Endpoint URL

```text
GET /api/crops/<id>/
```

### Example

```text
GET /api/crops/1/
```

### Full URL

```text
http://127.0.0.1:8000/api/crops/1/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns detailed information about a specific crop based on its ID.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response:**

```json
{
    "id": 1,
    "name": "Tomato",
    "scientific_name": "Solanum lycopersicum",
    "description": "Tomato is an important vegetable crop grown widely in tropical, subtropical, and temperate regions.",
    "image": "http://127.0.0.1:8000/media/crop_images/tomato.jpg"
}
```

### Error Response

If the crop does not exist:

```json
{
    "detail": "Not found."
}
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Crop details retrieved successfully |
| 404 | Crop not found |
| 500 | Internal server error |

---

# 5.3 Disease APIs

## 5.3.1 Get Disease List

### Endpoint URL

```text
GET /api/diseases/
```

### Full URL

```text
http://127.0.0.1:8000/api/diseases/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns a list of all diseases stored in the database.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response Format:**

```json
[
    {
        "id": 1,
        "name": "Early Blight",
        "crop": 1,
        "symptoms": "Small dark brown spots appear on older leaves.",
        "causes": "The disease is commonly associated with Alternaria solani.",
        "description": "Early blight is a common fungal disease of tomato.",
        "severity": "Medium",
        "image": "http://127.0.0.1:8000/media/disease_images/tomato_early_blight.jpg"
    },
    {
        "id": 2,
        "name": "Late Blight",
        "crop": 1,
        "symptoms": "Dark water-soaked lesions develop on leaves.",
        "causes": "Late blight is caused by Phytophthora infestans.",
        "description": "Late blight is a destructive disease of tomato.",
        "severity": "High",
        "image": "http://127.0.0.1:8000/media/disease_images/tomato_late_blight.jpg"
    }
]
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Disease list retrieved successfully |
| 500 | Internal server error |

---

## 5.3.2 Get Disease Details

### Endpoint URL

```text
GET /api/diseases/<id>/
```

### Example

```text
GET /api/diseases/1/
```

### Full URL

```text
http://127.0.0.1:8000/api/diseases/1/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns detailed information about a specific disease based on its ID.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response:**

```json
{
    "id": 1,
    "name": "Early Blight",
    "crop": 1,
    "symptoms": "Small dark brown spots appear on older leaves.",
    "causes": "The disease is commonly associated with Alternaria solani.",
    "description": "Early blight is a common fungal disease of tomato.",
    "severity": "Medium",
    "image": "http://127.0.0.1:8000/media/disease_images/tomato_early_blight.jpg"
}
```

### Error Response

```json
{
    "detail": "Not found."
}
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Disease details retrieved successfully |
| 404 | Disease not found |
| 500 | Internal server error |

---

# 5.4 Pesticide APIs

## 5.4.1 Get Pesticide List

### Endpoint URL

```text
GET /api/pesticides/
```

### Full URL

```text
http://127.0.0.1:8000/api/pesticides/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns a list of all pesticides available in the database.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response Format:**

```json
[
    {
        "id": 1,
        "name": "Amistar Top",
        "company_name": "Syngenta India Ltd.",
        "description": "Amistar Top is a broad-spectrum fungicide containing azoxystrobin and difenoconazole.",
        "price_range": "Verify current local price",
        "packing_size": "200 ml, 500 ml, 1 L",
        "dosage": "Use according to the current approved product label.",
        "spray_method": "Foliar spray according to crop-specific recommendations.",
        "precautions": "Use appropriate protective equipment and follow the approved product label.",
        "image": "http://127.0.0.1:8000/media/pesticide_images/amistar_top.jpg"
    }
]
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Pesticide list retrieved successfully |
| 500 | Internal server error |

---

## 5.4.2 Get Pesticide Details

### Endpoint URL

```text
GET /api/pesticides/<id>/
```

### Example

```text
GET /api/pesticides/1/
```

### Full URL

```text
http://127.0.0.1:8000/api/pesticides/1/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns complete information about a specific pesticide based on its ID.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response:**

```json
{
    "id": 1,
    "name": "Amistar Top",
    "company_name": "Syngenta India Ltd.",
    "description": "Amistar Top is a broad-spectrum fungicide containing azoxystrobin and difenoconazole.",
    "price_range": "Verify current local price",
    "packing_size": "200 ml, 500 ml, 1 L",
    "dosage": "Use according to the current approved product label.",
    "spray_method": "Foliar spray according to approved recommendations.",
    "precautions": "Use appropriate protective equipment and follow the approved product label.",
    "image": "http://127.0.0.1:8000/media/pesticide_images/amistar_top.jpg"
}
```

### Error Response

```json
{
    "detail": "Not found."
}
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Pesticide details retrieved successfully |
| 404 | Pesticide not found |
| 500 | Internal server error |

---

# 5.5 Recommendation API

## 5.5.1 Get Recommended Pesticides Based on Disease

### Endpoint URL

```text
GET /api/recommendations/<disease_id>/
```

### Example

```text
GET /api/recommendations/1/
```

### Full URL

```text
http://127.0.0.1:8000/api/recommendations/1/
```

### Request Method

```text
GET
```

### Request Body

No request body is required.

### Description

This API returns pesticides recommended for a particular disease.

The API uses the many-to-many relationship between Disease and Pesticide.

For example, if Disease ID `1` represents Tomato Early Blight, the API returns the pesticides mapped to that disease.

### Successful Response

**Status Code:**

```text
200 OK
```

**Response Format:**

```json
{
    "disease": {
        "id": 1,
        "name": "Early Blight"
    },
    "recommended_pesticides": [
        {
            "id": 1,
            "name": "Amistar",
            "company_name": "Syngenta India Ltd.",
            "description": "Amistar is a broad-spectrum fungicide based on azoxystrobin.",
            "price_range": "Verify current local price",
            "packing_size": "Available according to current product information",
            "dosage": "Use according to the current approved product label.",
            "spray_method": "Foliar spray according to approved recommendations.",
            "precautions": "Follow all current label instructions.",
            "image": "http://127.0.0.1:8000/media/pesticide_images/amistar.jpg"
        },
        {
            "id": 2,
            "name": "Score",
            "company_name": "Syngenta India Ltd.",
            "description": "Score is a systemic fungicide based on difenoconazole.",
            "price_range": "Verify current local price",
            "packing_size": "Available according to current product information",
            "dosage": "Use according to the current approved product label.",
            "spray_method": "Foliar spray according to approved recommendations.",
            "precautions": "Follow all current label instructions.",
            "image": "http://127.0.0.1:8000/media/pesticide_images/score.jpg"
        }
    ]
}
```

### Error Response

If the disease does not exist:

```json
{
    "detail": "Disease not found."
}
```

If no pesticides have been mapped:

```json
{
    "disease": {
        "id": 1,
        "name": "Early Blight"
    },
    "recommended_pesticides": []
}
```

### Status Codes

| Status Code | Description |
|---|---|
| 200 | Recommendations retrieved successfully |
| 404 | Disease not found |
| 500 | Internal server error |

---

# 5.6 Image Upload API

## 5.6.1 Upload Crop Leaf Image

### Endpoint URL

```text
POST /api/prediction/upload/
```

### Full URL

```text
http://127.0.0.1:8000/api/prediction/upload/
```

### Request Method

```text
POST
```

### Content Type

```text
multipart/form-data
```

### Request Body

The request must contain an image file with the key:

```text
image
```

### Example

```text
image = tomato_leaf.jpg
```

### Supported Image Formats

```text
JPG
JPEG
PNG
WEBP
```

### Maximum File Size

```text
5 MB
```

### Successful Response

**Status Code:**

```text
201 Created
```

**Response:**

```json
{
    "message": "Image uploaded successfully.",
    "image_id": 1,
    "image_url": "http://127.0.0.1:8000/media/leaf_images/tomato_leaf.jpg"
}
```

### Invalid File Response

**Status Code:**

```text
400 Bad Request
```

**Response:**

```json
{
    "errors": {
        "image": [
            "Only JPG, JPEG, PNG and WEBP images are allowed."
        ]
    }
}
```

### Large File Response

**Status Code:**

```text
400 Bad Request
```

**Response:**

```json
{
    "errors": {
        "image": [
            "Image size must not exceed 5 MB."
        ]
    }
}
```

### Status Codes

| Status Code | Description |
|---|---|
| 201 | Image uploaded successfully |
| 400 | Invalid image or request |
| 500 | Internal server error |

---

# 5.7 API Summary

| Module | API | Method | Purpose |
|---|---|---|---|
| Crop | `/api/crops/` | GET | Get all crops |
| Crop | `/api/crops/<id>/` | GET | Get crop details |
| Disease | `/api/diseases/` | GET | Get all diseases |
| Disease | `/api/diseases/<id>/` | GET | Get disease details |
| Pesticide | `/api/pesticides/` | GET | Get all pesticides |
| Pesticide | `/api/pesticides/<id>/` | GET | Get pesticide details |
| Recommendation | `/api/recommendations/<disease_id>/` | GET | Get recommended pesticides |
| Image Upload | `/api/prediction/upload/` | POST | Upload crop leaf image |

---

# 5.8 Frontend Integration Examples

## Get Crop List

```javascript
fetch("http://127.0.0.1:8000/api/crops/")
    .then(response => response.json())
    .then(data => {
        console.log(data);
    });
```

## Get Disease Details

```javascript
fetch("http://127.0.0.1:8000/api/diseases/1/")
    .then(response => response.json())
    .then(data => {
        console.log(data);
    });
```

## Get Recommended Pesticides

```javascript
fetch("http://127.0.0.1:8000/api/recommendations/1/")
    .then(response => response.json())
    .then(data => {
        console.log(data);
    });
```

## Upload Crop Leaf Image

```javascript
const formData = new FormData();

formData.append("image", imageFile);

fetch("http://127.0.0.1:8000/api/prediction/upload/", {
    method: "POST",
    body: formData
})
.then(response => response.json())
.then(data => {
    console.log(data);
});
```

> **Note:** Do not manually set the `Content-Type` header when using `FormData`. The browser automatically adds the correct `multipart/form-data` boundary.

---

# 5.9 Conclusion

The REST API documentation provides all necessary information for frontend integration, including endpoint URLs, HTTP methods, request formats, JSON response structures, and HTTP status codes. The APIs allow the frontend to retrieve crop, disease, pesticide, and recommendation information and upload crop leaf images for further processing by the Phytivra-AI system.
