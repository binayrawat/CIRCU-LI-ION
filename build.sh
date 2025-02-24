#!/bin/bash
set -e

# Activate virtual environment if it exists, create if it doesn't
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Define functions array
FUNCTIONS=("split_file" "process_chunk" "merge_results" "recipe_processor" "archive_creator")

# Create build directory
mkdir -p build

# Build each function
for func in "${FUNCTIONS[@]}"; do
    echo "Building $func..."
    
    # Create function directory
    mkdir -p "build/$func"
    
    # Install dependencies from function-specific requirements if exists
    if [ -f "$func/requirements.txt" ]; then
        pip install -r "$func/requirements.txt" --target "build/$func/"
    else
        pip install -r requirements.txt --target "build/$func/"
    fi
    
    # Copy source code
    if [ -f "$func/src/index.py" ]; then
        cp "$func/src/index.py" "build/$func/"
        
        # Create zip file
        cd "build/$func"
        zip -r "../../$func.zip" ./*
        cd ../..
        echo "✅ Built $func.zip"
    else
        echo "⚠️ Skipping $func - src/index.py not found"
    fi
done

# Cleanup
rm -rf build/

# Deactivate virtual environment
deactivate

echo "All Lambda functions built successfully!"
