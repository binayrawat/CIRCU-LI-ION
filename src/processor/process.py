import boto3
import click
import json
import os
import zipfile
from io import BytesIO
from datetime import datetime
from typing import Dict, Any

def process_recipe(bucket: str, input_key: str, output_key: str) -> bool:
    """
    Process a recipe from S3.
    
    The function:
    1. Reads a recipe JSON from S3
    2. Processes ingredients and instructions
    3. Adds nutritional information
    4. Saves as ZIP file back to S3
    """
    try:
        # Initialize S3 client
        s3 = boto3.client('s3')
        
        # Get the recipe file
        response = s3.get_object(Bucket=bucket, Key=input_key)
        recipe_data = json.loads(response['Body'].read().decode('utf-8'))
        
        # Process the recipe
        processed_recipe = {
            "name": recipe_data.get("name", ""),
            "ingredients": process_ingredients(recipe_data.get("ingredients", [])),
            "instructions": process_instructions(recipe_data.get("instructions", [])),
            "nutritional_info": calculate_nutrition(recipe_data.get("ingredients", [])),
            "metadata": {
                "processed_date": datetime.now().isoformat(),
                "version": "1.0"
            }
        }
        
        # Create ZIP file in memory
        zip_buffer = BytesIO()
        with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
            zip_file.writestr('recipe.json', json.dumps(processed_recipe, indent=2))
        
        # Upload processed ZIP file
        s3.put_object(
            Bucket=bucket,
            Key=output_key,
            Body=zip_buffer.getvalue(),
            ContentType='application/zip'
        )
        
        return True
        
    except Exception as e:
        print(f"Error processing recipe: {e}")
        raise

def process_ingredients(ingredients: list) -> list:
    """Process and standardize ingredients"""
    processed = []
    for ingredient in ingredients:
        processed.append({
            "item": ingredient.get("item", ""),
            "quantity": standardize_quantity(ingredient.get("quantity", "")),
            "unit": standardize_unit(ingredient.get("unit", "")),
            "notes": ingredient.get("notes", "")
        })
    return processed

def process_instructions(instructions: list) -> list:
    """Process and format instructions"""
    return [
        {
            "step": idx + 1,
            "text": instruction.strip(),
            "time_minutes": extract_time(instruction)
        }
        for idx, instruction in enumerate(instructions)
    ]

def calculate_nutrition(ingredients: list) -> Dict[str, Any]:
    """Calculate nutritional information"""
    # Placeholder for nutritional calculation
    return {
        "calories": 0,
        "protein": 0,
        "carbs": 0,
        "fat": 0,
        "fiber": 0
    }

def standardize_quantity(quantity: str) -> float:
    """Convert quantity to standard float"""
    try:
        return float(quantity.replace(',', '.'))
    except (ValueError, AttributeError):
        return 0.0

def standardize_unit(unit: str) -> str:
    """Standardize measurement units"""
    unit_map = {
        "g": "grams",
        "kg": "kilograms",
        "ml": "milliliters",
        "l": "liters",
        "tsp": "teaspoons",
        "tbsp": "tablespoons",
        "cup": "cups",
        "oz": "ounces",
        "lb": "pounds"
    }
    return unit_map.get(unit.lower(), unit.lower())

def extract_time(instruction: str) -> int:
    """Extract cooking time from instruction"""
    # Placeholder for time extraction
    return 0

@click.command()
@click.option('--bucket', required=True, help='S3 bucket name')
@click.option('--input-key', required=True, help='Input file key')
@click.option('--output-key', required=True, help='Output file key')
def main(bucket: str, input_key: str, output_key: str):
    """CLI interface for recipe processing"""
    success = process_recipe(bucket, input_key, output_key)
    if not success:
        exit(1)

if __name__ == "__main__":
    try:
        bucket = os.environ.get("RECIPE_BUCKET")
        input_key = os.environ.get("INPUT_KEY")
        output_key = os.environ.get("OUTPUT_KEY")
        
        if not all([bucket, input_key, output_key]):
            raise ValueError("Missing required environment variables")
            
        process_recipe(bucket, input_key, output_key)
    except Exception as e:
        print(f"Failed to process recipe: {e}")
        exit(1)