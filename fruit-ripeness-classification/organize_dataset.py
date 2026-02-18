#!/usr/bin/env python3
"""
Kaggle Fruit Ripeness Dataset Organizer
Reorganizes the dataset for Create ML training

Author: Created for FruitRipenessApp
Dataset: https://www.kaggle.com/datasets/ml50mudiarahmah/fruit-ripeness-classification
"""

import os
import shutil
from pathlib import Path
import sys

# Configuration
SOURCE_DIR = "."  # Current directory
TARGET_DIR = "FruitRipenessDataset"

# Fruit types in the dataset
FRUITS = ["banana", "mango", "papaya", "tomato", "apple", "strawberry", "grape", "dragon fruit", "durian"]
RIPENESS_LEVELS = ["unripe", "ripe", "overripe"]

def check_source_directory():
    """Check if source directory exists"""
    if not os.path.exists(SOURCE_DIR):
        print(f"❌ Error: Source directory '{SOURCE_DIR}' not found!")
        return False
    return True

def create_target_structure():
    """Create the target directory structure"""
    print("📁 Creating target directory structure...")
    
    # We'll create folders as we find images
    os.makedirs(TARGET_DIR, exist_ok=True)
    os.makedirs(f"{TARGET_DIR}/Training Data", exist_ok=True)
    os.makedirs(f"{TARGET_DIR}/Testing Data", exist_ok=True)
    
    print("✅ Directory structure created")

def normalize_name(name):
    """Normalize fruit/ripeness names"""
    return name.lower().replace(" ", "_").replace("-", "_")

def process_images():
    """Process and organize images from the flat folder structure"""
    stats = {"Training Data": {}, "Testing Data": {}}
    
    # Get all folders in the current directory
    all_folders = [f for f in os.listdir('.') if os.path.isdir(f) and f != TARGET_DIR and f != 'FruitRipenessDataset']
    
    print(f"\n📂 Found {len(all_folders)} folders to process")
    
    for folder in all_folders:
        folder_lower = folder.lower()
        
        # Determine ripeness from folder name
        ripeness = None
        if "unripe" in folder_lower:
            ripeness = "unripe"
        elif "overripe" in folder_lower:
            ripeness = "overripe"
        elif "ripe" in folder_lower:
            ripeness = "ripe"
        
        if not ripeness:
            print(f"  ⚠️  Skipping '{folder}' (can't detect ripeness)")
            continue
        
        # Determine fruit from folder name
        # Remove ripeness word to get fruit name
        fruit_name = folder_lower.replace("unripe", "").replace("overripe", "").replace("ripe", "").strip()
        
        if not fruit_name:
            print(f"  ⚠️  Skipping '{folder}' (can't detect fruit type)")
            continue
        
        # Normalize fruit name
        fruit_normalized = normalize_name(fruit_name)
        
        # Find images in this folder
        source_path = Path(folder)
        image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG']
        images = []
        for ext in image_extensions:
            images.extend(source_path.glob(ext))
        
        if not images:
            print(f"  ⚠️  No images found in '{folder}'")
            continue
        
        print(f"\n  📸 Processing '{folder}': {len(images)} images")
        print(f"     Detected: {fruit_normalized} - {ripeness}")
        
        # Split into Training (80%) and Testing (20%)
        split_idx = int(len(images) * 0.8)
        
        for i, img in enumerate(images):
            split = "Training Data" if i < split_idx else "Testing Data"
            
            # Create standardized folder name: "banana_ripe"
            target_category = f"{fruit_normalized}_{ripeness}"
            target_folder = Path(TARGET_DIR) / split / target_category
            target_folder.mkdir(parents=True, exist_ok=True)
            
            # Copy image
            try:
                shutil.copy2(img, target_folder / img.name)
                
                # Update stats
                if target_category not in stats[split]:
                    stats[split][target_category] = 0
                stats[split][target_category] += 1
            except Exception as e:
                print(f"     ⚠️  Error copying {img.name}: {e}")
        
        print(f"     ✅ Copied {split_idx} to Training, {len(images) - split_idx} to Testing")
    
    return stats

def print_statistics(stats):
    """Print final statistics"""
    print("\n" + "="*60)
    print("📊 DATASET STATISTICS")
    print("="*60)
    
    for split_name in ["Training Data", "Testing Data"]:
        print(f"\n{split_name}:")
        if not stats[split_name]:
            print("  (No images)")
            continue
        
        total = 0
        for category, count in sorted(stats[split_name].items()):
            print(f"  {category:30s}: {count:4d} images")
            total += count
        print(f"  {'-'*30}")
        print(f"  {'TOTAL':30s}: {total:4d} images")
    
    # Overall statistics
    training_total = sum(stats["Training Data"].values())
    testing_total = sum(stats["Testing Data"].values())
    grand_total = training_total + testing_total
    
    print(f"\n{'='*60}")
    print(f"📈 Grand Total: {grand_total} images")
    
    if grand_total > 0:
        print(f"📚 Training: {training_total} images ({training_total/grand_total*100:.1f}%)")
        print(f"🧪 Testing: {testing_total} images ({testing_total/grand_total*100:.1f}%)")
    
    print(f"{'='*60}")

def verify_organization():
    """Verify the organization was successful"""
    print("\n🔍 Verifying organization...")
    
    issues = []
    categories_found = set()
    
    for split in ["Training Data", "Testing Data"]:
        split_path = Path(TARGET_DIR) / split
        
        if not split_path.exists():
            issues.append(f"Missing folder: {split}")
            continue
        
        for category_folder in split_path.iterdir():
            if category_folder.is_dir():
                categories_found.add(category_folder.name)
                image_count = len(list(category_folder.glob("*")))
                if image_count == 0:
                    issues.append(f"Empty folder: {split}/{category_folder.name}")
    
    print(f"\n✅ Found {len(categories_found)} unique categories:")
    for category in sorted(categories_found):
        print(f"   - {category}")
    
    if issues:
        print("\n⚠️  Issues found:")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("\n✅ All folders have images!")

def main():
    """Main execution"""
    print("="*60)
    print("🍎 Kaggle Fruit Ripeness Dataset Organizer")
    print("="*60)
    
    # Check source directory
    if not check_source_directory():
        sys.exit(1)
    
    # Check if target already exists
    if os.path.exists(TARGET_DIR):
        response = input(f"\n⚠️  '{TARGET_DIR}' already exists. Overwrite? (y/n): ")
        if response.lower() != 'y':
            print("❌ Aborted")
            sys.exit(0)
        print("🗑️  Removing existing directory...")
        shutil.rmtree(TARGET_DIR)
    
    # Create structure
    create_target_structure()
    
    # Process images
    stats = process_images()
    
    # Print statistics
    print_statistics(stats)
    
    # Verify
    verify_organization()
    
    # Success message
    print("\n" + "="*60)
    print("🎉 DATASET REORGANIZATION COMPLETE!")
    print("="*60)
    print(f"\n📁 Output folder: {TARGET_DIR}/")
    print("\n📝 Next Steps:")
    print("1. Open Xcode")
    print("2. Menu: Xcode → Open Developer Tool → Create ML")
    print("3. File → New → Project → Image Classification")
    print(f"4. Drag '{TARGET_DIR}/Training Data' folder into Data section")
    print("5. Set Validation to 'Automatic'")
    print("6. Enable ALL Augmentation options:")
    print("   ✓ Blur, ✓ Crop, ✓ Exposure, ✓ Flip, ✓ Noise, ✓ Rotation")
    print("7. Set Max Iterations to 25-50")
    print("8. Click 'Train' button and wait!")
    print("\n✨ Good luck with your training! 🚀")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
