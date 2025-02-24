import json
import random

def generate_large_recipe():
    recipe = {
        "name": "Large Test Recipe",
        "variations": [],
        "detailed_instructions": [],
        "nutritional_info": [],
        "reviews": [],
        "images": []
    }

    # Generate large amount of data
    for i in range(10000):  # Reduced from 500000 to 10000
        variation = {
            "id": i,
            "ingredients": [
                {
                    "item": f"ingredient_{j}",
                    "amount": random.uniform(1, 1000),
                    "unit": "grams",
                    "notes": "x" * 2000  # Large text blocks
                } for j in range(50)  # Reduced from 100 to 50
            ],
            "instructions": [
                {
                    "step": k,
                    "description": "y" * 2000,  # Reduced from 4000 to 2000
                    "timing": random.randint(1, 120),
                    "temperature": random.randint(0, 500)
                } for k in range(25)  # Reduced from 50 to 25
            ]
        }
        recipe["variations"].append(variation)

        # Print progress
        if i % 1000 == 0:
            print(f"Generated {i} variations...")

    return recipe

if __name__ == "__main__":
    print("Starting to generate large recipe...")
    recipe = generate_large_recipe()
    print("Writing to file...")
    with open('large_recipe.json', 'w') as f:
        json.dump(recipe, f)
    print("Done!")
