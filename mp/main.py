import os
from datetime import datetime

from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from firebase_client import (
    save_sensor_data,
    save_item,
    save_notification
)
from ocr_engine import process_image
from expiry_engine import build_item_record

SERVER_BASE_URL = "http://10.168.12.204:8000"
IMAGE_DIR = "captured_images"

os.makedirs(IMAGE_DIR, exist_ok=True)

latest_sensor_data = {
    "temperature": 25,
    "humidity": 50,
    "gas_value": 0,
    "weight": 0
}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount(
    "/captured_images",
    StaticFiles(directory=IMAGE_DIR),
    name="captured_images"
)

print("=" * 60)
print("SMART FOOD MANAGEMENT SERVER")
print("=" * 60)
print(f"Image Folder: {os.path.abspath(IMAGE_DIR)}")
print("=" * 60)


@app.get("/")
async def root():
    return {
        "status": "running",
        "image_folder": IMAGE_DIR
    }


@app.get("/health")
async def health():
    return {
        "status": "online"
    }


@app.get("/images")
async def get_images():

    files = []

    for file in os.listdir(IMAGE_DIR):

        if file.lower().endswith(
            (".jpg", ".jpeg", ".png")
        ):

            files.append({
                "name": file,
                "url": f"{SERVER_BASE_URL}/captured_images/{file}"
            })

    files.sort(
        reverse=True,
        key=lambda x: x["name"]
    )

    return files


@app.post("/sensor")
async def receive_sensor(request: Request):

    data = await request.json()

    data["created_at"] = datetime.utcnow().isoformat()

    latest_sensor_data.update(data)

    print("\n===== SENSOR DATA =====")
    print(data)
    try:

        save_sensor_data(data)

        gas = data.get("gas_value", 0)
        temp = data.get("temperature", 0)
        humidity = data.get("humidity", 0)

        if gas >= 1800:

            save_notification(
            "Food spoilage detected. Gas level is very high."
        )

        elif gas >= 1000:

            save_notification(
            "Food may spoil soon. Gas level increasing."
        )

        if temp >= 35:

             save_notification(
            f"High refrigerator temperature: {temp}°C"
        )

        if humidity >= 85:

             save_notification(
            f"High refrigerator humidity: {humidity}%"
        )

        print("✅ Saved To Firestore")


    except Exception as e:
        print("❌ Firestore Error")
        print(str(e))

    return {
        "message": "Sensor received"
    }


@app.post("/upload-image")
async def upload_image(request: Request):

    image_bytes = await request.body()

    if not image_bytes:
        return {
            "message": "No image received"
        }

    timestamp = datetime.now().strftime(
        "%Y%m%d_%H%M%S"
    )

    filename = f"{timestamp}.jpg"

    filepath = os.path.join(
        IMAGE_DIR,
        filename
    )

    with open(filepath, "wb") as f:
        f.write(image_bytes)

    print(f"✅ Image Saved: {filepath}")

    image_url = (
        f"{SERVER_BASE_URL}/captured_images/{filename}"
    )

    try:

        ocr_result = process_image(filepath)

        print("\n===== OCR RESULT =====")
        print(ocr_result)

        item_type = (
            "packaged_food"
            if ocr_result.get("expiry_date")
            else "fresh_produce"
        )

        item = build_item_record(
            item_name=ocr_result.get(
                "product_name",
                "Unknown Item"
            ),
            item_type=item_type,
            expiry_date=ocr_result.get(
                "expiry_date"
            ),
            sensor_data=latest_sensor_data,
            image_url=image_url
        )

        save_item(item)

        days = 2

        if days <= 0:

         save_notification(
            f"{item['name']} has expired"
            )

        elif days == 1:

             save_notification(
                 f"{item['name']} will expire tomorrow"
            )

        elif days <= 3:

             save_notification(
                 f"{item['name']} will expire in {days} days"
            )

        print("✅ Item Saved To Firestore")

        return {
            "message": "Image uploaded",
            "ocr_result": ocr_result,
            "item": item
        }

    except Exception as e:

        print("❌ OCR ERROR")
        print(str(e))

        return {
            "message": "Image uploaded but OCR failed",
            "error": str(e)
        }

# =====================================
# RECIPE GENERATION
# =====================================
@app.post("/recipes")
async def generate_recipes(
    request: Request
):

    data = await request.json()

    ingredients = data.get(
        "ingredients",
        []
    )

    if not ingredients:

        return {
            "recipes":
            "No ingredients selected."
        }

    recipes = []

    if (
        "Tomato" in ingredients and
        "Onion" in ingredients
    ):
        recipes.append(
            "Tomato Onion Curry"
        )

    if (
        "Bread" in ingredients and
        "Milk" in ingredients
    ):
        recipes.append(
            "Bread Pudding"
        )

    if (
        "Eggs" in ingredients and
        "Onion" in ingredients
    ):
        recipes.append(
            "Omelette"
        )

    if (
        "Banana" in ingredients and
        "Milk" in ingredients
    ):
        recipes.append(
            "Banana Milkshake"
        )

    if (
        "Potato" in ingredients and
        "Onion" in ingredients
    ):
        recipes.append(
            "Potato Fry"
        )

    if (
        "Apple" in ingredients
    ):
        recipes.append(
            "Fresh Apple Salad"
        )

    if not recipes:

        recipes = [
            "Mixed Vegetable Curry",
            "Vegetable Stir Fry",
            "Healthy Salad",
            "Homemade Soup"
        ]

    return {

        "recipes":
        "\n".join(
            f"{i+1}. {recipe}"
            for i, recipe
            in enumerate(recipes)
        )
    }

@app.get("/test_alert")
async def test_alert():

    save_notification(
        "Test Alert Working"
    )

    return {
        "message":
        "alert created"
    }

if __name__ == "__main__":

    import uvicorn

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000
    )