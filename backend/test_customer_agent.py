"""
Simple test script for Customer Agent core functionality
"""

import asyncio
import sys
import os

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

async def test_basic_imports():
    """Test that all modules can be imported"""
    try:
        print("🧪 Testing basic imports...")
        
        # Test Customer Agent import
        from app.agents.customer_agent import CustomerAgent, ConversationContext
        print("✅ Customer Agent imported successfully")
        
        # Test Voice Service import  
        from app.services.voice_service import VoiceService
        print("✅ Voice Service imported successfully")
        
        # Test base agent
        from app.agents.base_agent import BaseAgent, AgentMessage
        print("✅ Base Agent imported successfully")
        
        return True
        
    except Exception as e:
        print(f"❌ Import test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_conversation_context():
    """Test ConversationContext functionality"""
    try:
        print("🧪 Testing ConversationContext...")
        
        from app.agents.customer_agent import ConversationContext
        
        # Create context
        context = ConversationContext(
            user_id="test-user-123",
            vehicle_id="test-vehicle-456",
            language="en"
        )
        
        # Test default values
        assert context.conversation_history == []
        assert context.context_data == {}
        assert context.current_intent is None
        
        # Test adding conversation history
        context.conversation_history.append({
            "role": "user",
            "content": "Hello",
            "timestamp": "2024-01-01T00:00:00"
        })
        
        assert len(context.conversation_history) == 1
        print("✅ ConversationContext tests passed")
        
        return True
        
    except Exception as e:
        print(f"❌ ConversationContext test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_intent_patterns():
    """Test intent recognition patterns"""
    try:
        print("🧪 Testing intent recognition patterns...")
        
        from app.agents.customer_agent import CustomerAgent
        
        # Create agent with minimal config
        config = {
            "ai_provider": "fallback",
            "voice_enabled": False,
            "conversation_timeout": 1800
        }
        
        agent = CustomerAgent(config)
        
        # Test intent patterns
        patterns = agent._initialize_intent_patterns()
        
        assert "vehicle_status" in patterns
        assert "maintenance_inquiry" in patterns
        assert "booking_request" in patterns
        assert "emergency" in patterns
        
        print("✅ Intent patterns initialized correctly")
        
        # Test response templates
        templates = agent._initialize_response_templates()
        
        assert "vehicle_status" in templates
        assert "maintenance_inquiry" in templates
        assert "general_inquiry" in templates
        
        print("✅ Response templates initialized correctly")
        
        return True
        
    except Exception as e:
        print(f"❌ Intent patterns test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_voice_service_basic():
    """Test VoiceService basic functionality"""
    try:
        print("🧪 Testing VoiceService basic functionality...")
        
        from app.services.voice_service import VoiceService
        
        # Create voice service
        voice_service = VoiceService()
        
        # Test supported languages
        languages = voice_service.get_supported_languages()
        assert len(languages) > 0
        print(f"✅ Found {len(languages)} supported languages")
        
        # Test language codes
        assert 'en' in voice_service.language_codes
        assert 'hi' in voice_service.language_codes
        print("✅ Language codes configured correctly")
        
        # Test TTS voices
        assert 'en' in voice_service.tts_voices
        assert 'hi' in voice_service.tts_voices
        print("✅ TTS voices configured correctly")
        
        return True
        
    except Exception as e:
        print(f"❌ VoiceService test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_agent_message():
    """Test AgentMessage functionality"""
    try:
        print("🧪 Testing AgentMessage...")
        
        from app.agents.base_agent import AgentMessage
        
        # Create agent message
        message = AgentMessage(
            sender="test_sender",
            recipient="test_recipient", 
            message_type="test_message",
            payload={"test": "data"}
        )
        
        # Test message properties
        assert message.sender == "test_sender"
        assert message.recipient == "test_recipient"
        assert message.message_type == "test_message"
        assert message.payload["test"] == "data"
        assert message.priority == 1  # default
        
        # Test to_dict method
        message_dict = message.to_dict()
        assert "id" in message_dict
        assert "timestamp" in message_dict
        assert message_dict["sender"] == "test_sender"
        
        print("✅ AgentMessage tests passed")
        
        return True
        
    except Exception as e:
        print(f"❌ AgentMessage test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def main():
    """Run all tests"""
    print("🚀 Starting Customer Agent core functionality tests...\n")
    
    tests = [
        test_basic_imports,
        test_conversation_context,
        test_intent_patterns,
        test_voice_service_basic,
        test_agent_message
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            result = await test()
            if result:
                passed += 1
            print()
        except Exception as e:
            print(f"❌ Test {test.__name__} failed with exception: {e}")
            print()
    
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Customer Agent implementation is working correctly.")
    else:
        print("⚠️ Some tests failed. Please check the implementation.")
    
    return passed == total

if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)