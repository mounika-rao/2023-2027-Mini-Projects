import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime

cred = credentials.Certificate(
    "serviceAccountKey.json"
)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()


def save_sensor_data(data):
    db.collection(
        "sensor_readings"
    ).add(data)


def save_item(item_data):

    db.collection(
        "items"
    ).document(
        item_data["item_id"]
    ).set(item_data)


def get_item(item_id):

    doc = db.collection(
        "items"
    ).document(
        item_id
    ).get()

    if doc.exists:
        return doc.to_dict()

    return None


def save_notification(
    message,
    item_id=None
):
    db.collection(
        "notifications"
    ).add({
        "item_id": item_id,
        "title": "Expiry Alert",
        "body": message,
        "message": message,
        "created_at": datetime.utcnow(),
        "read": False
    })


def save_recipe(recipe):

    db.collection(
        "recipes"
    ).add(recipe)


def save_image_metadata(data):

    db.collection(
        "images"
    ).add(data)
