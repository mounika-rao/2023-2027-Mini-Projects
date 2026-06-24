from firebase_client import save_notification

def create_notification(
    item_name,
    days_remaining,
    sensor_data=None
):

    if sensor_data is None:
        sensor_data = {}

    gas_value = sensor_data.get(
        "gas_value",
        0
    )

    temperature = sensor_data.get(
        "temperature",
        0
    )

    humidity = sensor_data.get(
        "humidity",
        0
    )

    # Expiry Alerts

    if days_remaining is not None:

        if days_remaining <= 0:

            save_notification(
                f"{item_name} has expired"
            )

        elif days_remaining == 1:

            save_notification(
                f"{item_name} will expire tomorrow"
            )

        elif days_remaining <= 3:

            save_notification(
                f"{item_name} will expire in {days_remaining} days"
            )

    # Gas Sensor Alerts

    if gas_value >= 1800:

        save_notification(
            f"High spoilage gas detected near {item_name}"
        )

    elif gas_value >= 1000:

        save_notification(
            f"{item_name} may spoil soon"
        )

    # Temperature Alert

    if temperature >= 35:

        save_notification(
            f"High refrigerator temperature ({temperature}°C)"
        )

    # Humidity Alert

    if humidity >= 85:

        save_notification(
            f"High refrigerator humidity ({humidity}%)"
        )