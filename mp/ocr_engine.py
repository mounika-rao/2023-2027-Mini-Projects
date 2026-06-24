import cv2
import pytesseract
import re
from datetime import datetime

# Windows Example
pytesseract.pytesseract.tesseract_cmd = (
    r"C:\Program Files\Tesseract-OCR\tesseract.exe"
)


def extract_text(image_path):

    image = cv2.imread(image_path)

    gray = cv2.cvtColor(
        image,
        cv2.COLOR_BGR2GRAY
    )

    text = pytesseract.image_to_string(
        gray
    )

    return text


def extract_expiry_date(text):

    patterns = [

        r"\d{2}/\d{2}/\d{4}",
        r"\d{2}-\d{2}-\d{4}",
        r"\d{4}-\d{2}-\d{2}"
    ]

    for pattern in patterns:

        match = re.search(
            pattern,
            text
        )

        if match:

            date_str = match.group()

            for fmt in [
                "%d/%m/%Y",
                "%d-%m-%Y",
                "%Y-%m-%d"
            ]:

                try:

                    return datetime.strptime(
                        date_str,
                        fmt
                    ).isoformat()

                except:
                    pass

    return None


def extract_product_name(text):

    lines = text.split("\n")

    for line in lines:

        line = line.strip()

        if len(line) > 3:

            return line

    return "Unknown Item"


def process_image(
    image_path
):

    text = extract_text(
        image_path
    )

    product_name = extract_product_name(
        text
    )

    expiry_date = extract_expiry_date(
        text
    )

    return {

        "product_name":
        product_name,

        "expiry_date":
        expiry_date,

        "raw_text":
        text
    }