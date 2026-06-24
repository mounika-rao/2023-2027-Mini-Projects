import anthropic

# Get a key from https://console.anthropic.com -> Settings -> API Keys
API_KEY = "YOUR_API_KEY_HERE"

client = anthropic.Anthropic(api_key=API_KEY)


def generate_recipe(ingredients):

    ingredient_text = ", ".join(ingredients)

    prompt = f"""You are a cooking assistant.

Suggest 3 different recipes using some or all of the ingredients below.
For each recipe include:
1. Recipe Name
2. Ingredients
3. Step by Step Instructions

Available Ingredients:
{ingredient_text}

Clearly number the recipes 1, 2, and 3, with a blank line between each one."""

    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2048,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return message.content[0].text