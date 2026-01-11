"""
Minimal test to check imports
"""

import sys
import os

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_imports():
    """Test basic imports"""
    try:
        print("Testing dataclass import...")
        from dataclasses import dataclass
        print("✅ dataclass imported")
        
        print("Testing datetime import...")
        from datetime import datetime
        print("✅ datetime imported")
        
        print("Testing typing import...")
        from typing import Dict, Any, List, Optional
        print("✅ typing imported")
        
        print("Testing asyncio import...")
        import asyncio
        print("✅ asyncio imported")
        
        print("Testing re import...")
        import re
        print("✅ re imported")
        
        print("Testing json import...")
        import json
        print("✅ json imported")
        
        print("All basic imports successful!")
        return True
        
    except Exception as e:
        print(f"❌ Import failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_imports()
    print(f"Test result: {'PASS' if success else 'FAIL'}")