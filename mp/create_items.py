import os
from datetime import datetime
from firebase_client import save_item

SERVER_BASE_URL = "http://10.168.12.204:8000"
IMAGE_DIR = "captured_images"

for file in os.listdir(IMAGE_DIR):

    if file.lower().endswith((".jpg", ".jpeg", ".png")):

        item = {
            "item_id": file.replace(".", "_"),
            "name": "Tomato",
            "item_type": "fresh_produce",
            "expiry_date": None,
            "days_remaining": 5,
            "freshness_score": 100,
            "status": "FRESH",
            "created_at": datetime.utcnow().isoformat(),
            "image_url": f"{SERVER_BASE_URL}/captured_images/{file}"
        }

        save_item(item)

        print("Saved:", file)