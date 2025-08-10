#!/bin/bash
# Path: /home/ransomeye/ransomeye/ransomeyeinstaller/build_deb_package.sh
# Author: nXxBku0CKFAJCBN3X1g3bQk7OxYQylg8CMw1iGsq7gU
# Description: Build script for RansomEye Deception Framework .deb package

set -e

echo "🚀 Building RansomEye Deception Framework .deb package..."

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found. Please run this script from the ransomeyeinstaller directory."
    exit 1
fi

# Install build dependencies
echo "📦 Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential devscripts debhelper python3 python3-pip python3-venv

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf debian/ransomeye-deception
rm -f ../ransomeye-deception_*.deb

# Make debian scripts executable
chmod +x debian/rules
chmod +x debian/postinst
chmod +x debian/prerm
chmod +x debian/postrm

# Build the package
echo "🔨 Building package..."
dpkg-buildpackage -b -us -uc

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Package built successfully!"
    
    # Find the built package
    PACKAGE_FILE=$(find .. -name "ransomeye-deception_*.deb" | head -1)
    
    if [ -n "$PACKAGE_FILE" ]; then
        echo "📦 Package location: $PACKAGE_FILE"
        echo "📊 Package size: $(du -h "$PACKAGE_FILE" | cut -f1)"
        
        # Show package information
        echo "📋 Package information:"
        dpkg-deb -I "$PACKAGE_FILE"
        
        echo ""
        echo "🎉 RansomEye Deception Framework .deb package is ready!"
        echo "📦 Install with: sudo dpkg -i $PACKAGE_FILE"
        echo "🔧 Fix dependencies: sudo apt-get install -f"
        echo "🚀 Start service: sudo systemctl start ransomeye-deception"
        echo "📊 Check status: sudo systemctl status ransomeye-deception"
        echo "🛠️  CLI tool: ransomeye-deception-cli --help"
        
    else
        echo "❌ Error: Package file not found after build"
        exit 1
    fi
else
    echo "❌ Error: Package build failed"
    exit 1
fi
