from datetime import datetime


def calculate_days_remaining(
    expiry_date
):
    try:

        expiry = datetime.fromisoformat(
            expiry_date
        )

        now = datetime.now()

        return (
            expiry - now
        ).days

    except:
        return None


def freshness_score(
    temperature,
    humidity,
    gas_value
):

    score = 100

    if temperature > 30:
        score -= 20

    if humidity > 70:
        score -= 15

    if gas_value > 1000:
        score -= 20

    if gas_value > 2000:
        score -= 25

    return max(
        score,
        0
    )


def get_status(
    days_remaining,
    freshness
):

    if days_remaining is not None:

        if days_remaining <= 0:
            return "EXPIRED"

        elif days_remaining <= 3:
            return "NEAR_EXPIRY"

        elif days_remaining <= 7:
            return "USE_SOON"

        else:
            return "FRESH"

    else:

        if freshness >= 80:
            return "FRESH"

        elif freshness >= 50:
            return "USE_SOON"

        else:
            return "NEAR_EXPIRY"


def build_item_record(
    item_name,
    item_type,
    expiry_date,
    sensor_data,
    image_url=None
):

    days_remaining = None

    if expiry_date:
        days_remaining = calculate_days_remaining(
            expiry_date
        )

    # Sensor readings only meaningful for fresh produce (fruits/vegetables)
    is_fresh_produce = item_type == "fresh_produce"

    if is_fresh_produce:
        freshness = freshness_score(
            sensor_data.get("temperature", 25),
            sensor_data.get("humidity", 50),
            sensor_data.get("gas_value", 0)
        )
        temperature = sensor_data.get("temperature")
        humidity    = sensor_data.get("humidity")
        gas_value   = sensor_data.get("gas_value")
        weight      = sensor_data.get("weight")
    else:
        # Packaged food — ignore sensor readings, rely on OCR expiry date only
        freshness   = None
        temperature = None
        humidity    = None
        gas_value   = None
        weight      = None

    status = get_status(
        days_remaining,
        freshness
    )

    return {

        "item_id":
        item_name.lower().replace(
            " ",
            "_"
        ),

        "name":
        item_name,

        "item_type":
        item_type,

        "expiry_date":
        expiry_date,

        "days_remaining":
        days_remaining,

        "freshness_score":
        freshness,

        "status":
        status,

        "last_updated":
        datetime.utcnow().isoformat(),

        "created_at":
        datetime.utcnow().isoformat(),

        "temperature":
        temperature,

        "humidity":
        humidity,

        "gas_value":
        gas_value,

        "weight":
        weight,

        "image_url":
        image_url
    }