"""
AIVONITY App Icon Generator
Generates app icons for Android, iOS, Web, Windows, macOS, and Linux
"""

from PIL import Image
import os
import shutil

# Source logo path
SOURCE_LOGO = "../windows/runner/resources/App_icon.png"

# Base directory (aivonity_app)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Icon configurations for each platform
ANDROID_ICONS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

WEB_ICONS = {
    "favicon.png": 16,
    "icons/Icon-192.png": 192,
    "icons/Icon-512.png": 512,
    "icons/Icon-maskable-192.png": 192,
    "icons/Icon-maskable-512.png": 512,
}

WINDOWS_ICON_SIZE = 256
MACOS_ICONS = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}

def resize_image(source_path, target_path, size):
    """Resize image to specified size maintaining aspect ratio"""
    with Image.open(source_path) as img:
        # Convert to RGBA if necessary
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Resize with high quality
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        
        # Save
        resized.save(target_path, 'PNG', optimize=True)
        print(f"  ✓ Created: {os.path.basename(target_path)} ({size}x{size})")

def generate_android_icons(source_path):
    """Generate Android launcher icons"""
    print("\n📱 Generating Android icons...")
    android_res_dir = os.path.join(BASE_DIR, "android", "app", "src", "main", "res")
    
    for folder, size in ANDROID_ICONS.items():
        target_dir = os.path.join(android_res_dir, folder)
        target_path = os.path.join(target_dir, "ic_launcher.png")
        resize_image(source_path, target_path, size)

def generate_ios_icons(source_path):
    """Generate iOS app icons"""
    print("\n🍎 Generating iOS icons...")
    ios_icon_dir = os.path.join(BASE_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    
    for filename, size in IOS_ICONS.items():
        target_path = os.path.join(ios_icon_dir, filename)
        resize_image(source_path, target_path, size)

def generate_web_icons(source_path):
    """Generate Web icons"""
    print("\n🌐 Generating Web icons...")
    web_dir = os.path.join(BASE_DIR, "web")
    
    for filename, size in WEB_ICONS.items():
        target_path = os.path.join(web_dir, filename)
        resize_image(source_path, target_path, size)

def generate_windows_icon(source_path):
    """Generate Windows icon"""
    print("\n🪟 Generating Windows icon...")
    windows_res_dir = os.path.join(BASE_DIR, "windows", "runner", "resources")
    
    # Generate PNG icon
    target_path = os.path.join(windows_res_dir, "app_icon.ico")
    
    with Image.open(source_path) as img:
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Create multiple sizes for ICO
        sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        icons = []
        for size in sizes:
            resized = img.resize(size, Image.Resampling.LANCZOS)
            icons.append(resized)
        
        # Save as ICO
        icons[0].save(target_path, format='ICO', sizes=[(s[0], s[1]) for s in sizes])
        print(f"  ✓ Created: app_icon.ico (multi-size)")

def generate_macos_icons(source_path):
    """Generate macOS app icons"""
    print("\n🍏 Generating macOS icons...")
    macos_icon_dir = os.path.join(BASE_DIR, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    
    for filename, size in MACOS_ICONS.items():
        target_path = os.path.join(macos_icon_dir, filename)
        resize_image(source_path, target_path, size)

def main():
    print("=" * 50)
    print("🚗 AIVONITY App Icon Generator")
    print("=" * 50)
    
    # Get source logo path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    source_path = os.path.join(script_dir, SOURCE_LOGO)
    
    if not os.path.exists(source_path):
        print(f"❌ Error: Source logo not found at {source_path}")
        return
    
    print(f"\n📁 Source logo: {source_path}")
    
    # Generate icons for all platforms
    generate_android_icons(source_path)
    generate_ios_icons(source_path)
    generate_web_icons(source_path)
    generate_windows_icon(source_path)
    generate_macos_icons(source_path)
    
    print("\n" + "=" * 50)
    print("✅ All app icons generated successfully!")
    print("=" * 50)
    print("\nNext steps:")
    print("  1. Run 'flutter clean'")
    print("  2. Run 'flutter pub get'")
    print("  3. Rebuild your app")

if __name__ == "__main__":
    main()
