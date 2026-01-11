"""
AIVONITY Customer Agent
Advanced conversational AI interface for customer interactions
"""

import asyncio
import json
import re
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
import aiohttp
import openai
from anthropic import AsyncAnthropic

from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.models import Vehicle, TelemetryData, MaintenancePrediction, User
from app.db.database import AsyncSessionLocal
from app.config import settings
from app.utils.logging_config import get_logger
from app.services.voice_service import voice_service

@dataclass
class ConversationContext:
    """Context for maintaining conversation state"""
    user_id: str
    vehicle_id: Optional[str] = None
    conversation_history: List[Dict[str, Any]] = None
    current_intent: Optional[str] = None
    context_data: Dict[str, Any] = None
    language: str = "en"
    
    def __post_init__(self):
        if self.conversation_history is None:
            self.conversation_history = []
        if self.context_data is None:
            self.context_data = {}

@dataclass
class VoiceRequest:
    """Voice interaction request structure"""
    audio_data: bytes
    language: str = "en"
    user_id: str = ""
    vehicle_id: Optional[str] = None

class CustomerAgent(BaseAgent):
    """
    Advanced Customer Agent for conversational AI interactions
    Handles text and voice conversations with context awareness
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("customer_agent", config)
        
        # AI Service Configuration
        self.openai_client = None
        self.anthropic_client = None
        self.ai_provider = config.get("ai_provider", "openai")  # openai or anthropic
        
        # Conversation Management
        self.active_conversations: Dict[str, ConversationContext] = {}
        self.conversation_timeout = config.get("conversation_timeout", 1800)  # 30 minutes
        
        # Intent Recognition
        self.intent_patterns = self._initialize_intent_patterns()
        
        # Response Templates
        self.response_templates = self._initialize_response_templates()
        
        # Voice Processing
        self.voice_enabled = config.get("voice_enabled", True)
        self.supported_languages = settings.SUPPORTED_LANGUAGES
        
        # Context Management
        self.max_context_messages = config.get("max_context_messages", 10)
        self.context_cleanup_interval = config.get("context_cleanup_interval", 300)  # 5 minutes

    def _define_capabilities(self) -> List[str]:
        """Define Customer Agent capabilities"""
        return [
            "text_conversation",
            "voice_interaction", 
            "intent_recognition",
            "context_management",
            "vehicle_status_queries",
            "maintenance_assistance",
            "multi_language_support",
            "conversation_history",
            "emergency_detection"
        ]

    async def _initialize_resources(self):
        """Initialize AI clients and resources"""
        try:
            # Initialize AI clients
            if settings.OPENAI_API_KEY:
                openai.api_key = settings.OPENAI_API_KEY
                self.openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
                self.logger.info("✅ OpenAI client initialized")
            
            if settings.ANTHROPIC_API_KEY:
                self.anthropic_client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
                self.logger.info("✅ Anthropic client initialized")
            
            if not self.openai_client and not self.anthropic_client:
                self.logger.warning("⚠️ No AI service configured - using fallback responses")
            
            # Start context cleanup task
            asyncio.create_task(self._context_cleanup_loop())
            
            self.logger.info("✅ Customer Agent resources initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Customer Agent resources: {e}")
            raise

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming customer interaction messages"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            if message_type == "chat_message":
                return await self._process_chat_message(payload, message.correlation_id)
            
            elif message_type == "voice_message":
                return await self._process_voice_message(payload, message.correlation_id)
            
            elif message_type == "context_update":
                return await self._update_conversation_context(payload, message.correlation_id)
            
            elif message_type == "conversation_history":
                return await self._get_conversation_history(payload, message.correlation_id)
            
            elif message_type == "emergency_detected":
                return await self._handle_emergency(payload, message.correlation_id)
            
            else:
                self.logger.warning(f"⚠️ Unknown message type: {message_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"❌ Error processing message: {e}")
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="error",
                payload={"error": str(e), "original_message_id": message.id},
                correlation_id=message.correlation_id
            )

    async def _process_chat_message(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process text-based chat message"""
        try:
            user_id = payload.get("user_id")
            message_text = payload.get("message", "")
            vehicle_id = payload.get("vehicle_id")
            language = payload.get("language", "en")
            
            # Get or create conversation context
            context = await self._get_conversation_context(user_id, vehicle_id, language)
            
            # Recognize intent
            intent = await self._recognize_intent(message_text, context)
            context.current_intent = intent
            
            # Add user message to history
            context.conversation_history.append({
                "role": "user",
                "content": message_text,
                "timestamp": datetime.utcnow().isoformat(),
                "intent": intent
            })
            
            # Generate AI response
            ai_response = await self._generate_ai_response(message_text, context)
            
            # Add AI response to history
            context.conversation_history.append({
                "role": "assistant", 
                "content": ai_response,
                "timestamp": datetime.utcnow().isoformat()
            })
            
            # Trim conversation history if too long
            if len(context.conversation_history) > self.max_context_messages * 2:
                context.conversation_history = context.conversation_history[-self.max_context_messages * 2:]
            
            # Update context
            self.active_conversations[user_id] = context
            
            # Prepare response
            response_payload = {
                "user_id": user_id,
                "response": ai_response,
                "intent": intent,
                "language": language,
                "conversation_id": correlation_id,
                "response_metadata": {
                    "response_time": datetime.utcnow().isoformat(),
                    "ai_provider": self.ai_provider,
                    "context_length": len(context.conversation_history)
                }
            }
            
            return AgentMessage(
                sender=self.agent_name,
                recipient="websocket_manager",
                message_type="chat_response",
                payload=response_payload,
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error processing chat message: {e}")
            raise

    async def _process_voice_message(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process voice-based message"""
        try:
            user_id = payload.get("user_id")
            audio_data = payload.get("audio_data")
            language = payload.get("language", "en")
            vehicle_id = payload.get("vehicle_id")
            
            # Convert speech to text
            transcribed_text = await self._speech_to_text(audio_data, language)
            
            if not transcribed_text:
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="websocket_manager",
                    message_type="voice_response",
                    payload={
                        "user_id": user_id,
                        "error": "Could not transcribe audio",
                        "language": language
                    },
                    correlation_id=correlation_id
                )
            
            # Process as text message
            text_payload = {
                "user_id": user_id,
                "message": transcribed_text,
                "vehicle_id": vehicle_id,
                "language": language
            }
            
            chat_response = await self._process_chat_message(text_payload, correlation_id)
            
            # Convert response to speech
            response_text = chat_response.payload.get("response", "")
            audio_response = await self._text_to_speech(response_text, language)
            
            # Prepare voice response
            response_payload = {
                "user_id": user_id,
                "transcribed_text": transcribed_text,
                "response_text": response_text,
                "audio_response": audio_response,
                "language": language,
                "conversation_id": correlation_id
            }
            
            return AgentMessage(
                sender=self.agent_name,
                recipient="websocket_manager", 
                message_type="voice_response",
                payload=response_payload,
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error processing voice message: {e}")
            raise

    async def _recognize_intent(self, message: str, context: ConversationContext) -> str:
        """Recognize user intent from message"""
        try:
            message_lower = message.lower()
            
            # Check for emergency keywords first
            emergency_keywords = ["emergency", "urgent", "help", "accident", "breakdown", "stuck"]
            if any(keyword in message_lower for keyword in emergency_keywords):
                return "emergency"
            
            # Check intent patterns
            for intent, patterns in self.intent_patterns.items():
                for pattern in patterns:
                    if re.search(pattern, message_lower):
                        return intent
            
            # Use AI for complex intent recognition if available
            if self.openai_client or self.anthropic_client:
                ai_intent = await self._ai_intent_recognition(message, context)
                if ai_intent:
                    return ai_intent
            
            return "general_inquiry"
            
        except Exception as e:
            self.logger.error(f"❌ Error recognizing intent: {e}")
            return "general_inquiry"

    async def _ai_intent_recognition(self, message: str, context: ConversationContext) -> Optional[str]:
        """Use AI for advanced intent recognition"""
        try:
            intent_prompt = f"""
            Analyze the following user message and classify the intent. 
            Consider the conversation context and vehicle-related domain.
            
            User message: "{message}"
            
            Available intents:
            - vehicle_status: asking about vehicle health, diagnostics, alerts
            - maintenance_inquiry: questions about maintenance, repairs, service
            - booking_request: wanting to schedule service appointments
            - emergency: urgent help, breakdowns, accidents
            - general_inquiry: general questions, greetings, other topics
            
            Respond with only the intent name.
            """
            
            if self.ai_provider == "openai" and self.openai_client:
                response = await self.openai_client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[{"role": "user", "content": intent_prompt}],
                    max_tokens=50,
                    temperature=0.1
                )
                return response.choices[0].message.content.strip()
            
            elif self.ai_provider == "anthropic" and self.anthropic_client:
                response = await self.anthropic_client.messages.create(
                    model="claude-3-haiku-20240307",
                    max_tokens=50,
                    messages=[{"role": "user", "content": intent_prompt}]
                )
                return response.content[0].text.strip()
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Error in AI intent recognition: {e}")
            return None

    async def _generate_ai_response(self, message: str, context: ConversationContext) -> str:
        """Generate AI response based on message and context"""
        try:
            # Get vehicle context if available
            vehicle_context = ""
            if context.vehicle_id:
                vehicle_data = await self._get_vehicle_context(context.vehicle_id)
                vehicle_context = f"\nVehicle Context: {json.dumps(vehicle_data, indent=2)}"
            
            # Build conversation history for context
            history_context = ""
            if context.conversation_history:
                recent_history = context.conversation_history[-6:]  # Last 3 exchanges
                history_context = "\nRecent conversation:\n"
                for msg in recent_history:
                    role = "User" if msg["role"] == "user" else "Assistant"
                    history_context += f"{role}: {msg['content']}\n"
            
            # Create system prompt
            system_prompt = f"""
            You are AIVONITY, an intelligent vehicle assistant. You help vehicle owners with:
            - Vehicle health monitoring and diagnostics
            - Maintenance recommendations and scheduling
            - Troubleshooting vehicle issues
            - General vehicle-related questions
            
            Guidelines:
            - Be helpful, friendly, and professional
            - Provide specific, actionable advice when possible
            - If you need more information, ask clarifying questions
            - For emergencies, prioritize safety and immediate assistance
            - Keep responses concise but informative
            - Use the vehicle context to provide personalized responses
            
            Current user intent: {context.current_intent}
            Language: {context.language}
            {vehicle_context}
            {history_context}
            """
            
            # Generate response using AI
            if self.ai_provider == "openai" and self.openai_client:
                response = await self.openai_client.chat.completions.create(
                    model="gpt-4",
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": message}
                    ],
                    max_tokens=settings.AI_MAX_TOKENS,
                    temperature=settings.AI_MODEL_TEMPERATURE
                )
                return response.choices[0].message.content
            
            elif self.ai_provider == "anthropic" and self.anthropic_client:
                response = await self.anthropic_client.messages.create(
                    model="claude-3-sonnet-20240229",
                    max_tokens=settings.AI_MAX_TOKENS,
                    system=system_prompt,
                    messages=[{"role": "user", "content": message}]
                )
                return response.content[0].text
            
            else:
                # Fallback to template-based responses
                return await self._generate_template_response(message, context)
            
        except Exception as e:
            self.logger.error(f"❌ Error generating AI response: {e}")
            return await self._generate_template_response(message, context)

    async def _generate_template_response(self, message: str, context: ConversationContext) -> str:
        """Generate response using templates when AI is not available"""
        try:
            intent = context.current_intent or "general_inquiry"
            
            if intent in self.response_templates:
                template = self.response_templates[intent]
                
                # Simple template variable replacement
                if context.vehicle_id:
                    vehicle_data = await self._get_vehicle_context(context.vehicle_id)
                    template = template.replace("{vehicle_make}", vehicle_data.get("make", "your vehicle"))
                    template = template.replace("{vehicle_model}", vehicle_data.get("model", ""))
                    template = template.replace("{health_score}", str(vehicle_data.get("health_score", "N/A")))
                
                return template
            
            return "I'm here to help with your vehicle needs. Could you please provide more details about what you'd like to know?"
            
        except Exception as e:
            self.logger.error(f"❌ Error generating template response: {e}")
            return "I apologize, but I'm having trouble processing your request right now. Please try again."

    async def _get_vehicle_context(self, vehicle_id: str) -> Dict[str, Any]:
        """Get vehicle context data for conversation"""
        try:
            async with AsyncSessionLocal() as session:
                # Get vehicle info
                vehicle = await session.get(Vehicle, vehicle_id)
                if not vehicle:
                    return {}
                
                # Get recent telemetry
                recent_telemetry = await session.execute(
                    f"""
                    SELECT sensor_data, anomaly_score, timestamp 
                    FROM telemetry_data 
                    WHERE vehicle_id = '{vehicle_id}' 
                    ORDER BY timestamp DESC 
                    LIMIT 1
                    """
                )
                telemetry_data = recent_telemetry.fetchone()
                
                # Get active predictions
                predictions = await session.execute(
                    f"""
                    SELECT component, failure_probability, recommended_action 
                    FROM maintenance_predictions 
                    WHERE vehicle_id = '{vehicle_id}' AND status = 'pending'
                    ORDER BY failure_probability DESC
                    LIMIT 3
                    """
                )
                prediction_data = predictions.fetchall()
                
                return {
                    "make": vehicle.make,
                    "model": vehicle.model,
                    "year": vehicle.year,
                    "health_score": vehicle.health_score,
                    "mileage": vehicle.mileage,
                    "recent_telemetry": dict(telemetry_data._mapping) if telemetry_data else None,
                    "active_predictions": [dict(p._mapping) for p in prediction_data] if prediction_data else []
                }
                
        except Exception as e:
            self.logger.error(f"❌ Error getting vehicle context: {e}")
            return {}

    async def _get_conversation_context(self, user_id: str, vehicle_id: Optional[str] = None, 
                                      language: str = "en") -> ConversationContext:
        """Get or create conversation context"""
        if user_id in self.active_conversations:
            context = self.active_conversations[user_id]
            # Update vehicle_id if provided
            if vehicle_id:
                context.vehicle_id = vehicle_id
            context.language = language
            return context
        
        # Create new context
        context = ConversationContext(
            user_id=user_id,
            vehicle_id=vehicle_id,
            language=language
        )
        self.active_conversations[user_id] = context
        return context

    async def _speech_to_text(self, audio_data: bytes, language: str = "en") -> Optional[str]:
        """Convert speech to text using voice service"""
        try:
            if not self.voice_enabled:
                return None
            
            # Use voice service for speech-to-text
            result = await voice_service.speech_to_text(audio_data, language)
            
            if result['success']:
                self.logger.info(f"✅ Speech transcribed: {result['transcription'][:50]}...")
                return result['transcription']
            else:
                self.logger.warning(f"⚠️ Speech-to-text failed: {result.get('error', 'Unknown error')}")
                return None
            
        except Exception as e:
            self.logger.error(f"❌ Error in speech-to-text: {e}")
            return None

    async def _text_to_speech(self, text: str, language: str = "en") -> Optional[bytes]:
        """Convert text to speech using voice service"""
        try:
            if not self.voice_enabled:
                return None
            
            # Use voice service for text-to-speech
            result = await voice_service.text_to_speech(text, language)
            
            if result['success']:
                self.logger.info(f"✅ Text converted to speech: {len(text)} characters")
                return result['audio_data']
            else:
                self.logger.warning(f"⚠️ Text-to-speech failed: {result.get('error', 'Unknown error')}")
                return None
            
        except Exception as e:
            self.logger.error(f"❌ Error in text-to-speech: {e}")
            return None

    def _initialize_intent_patterns(self) -> Dict[str, List[str]]:
        """Initialize regex patterns for intent recognition"""
        return {
            "vehicle_status": [
                r"how.*is.*my.*car",
                r"vehicle.*status",
                r"health.*score",
                r"any.*alerts",
                r"dashboard.*show",
                r"what.*wrong.*with.*car"
            ],
            "maintenance_inquiry": [
                r"when.*maintenance",
                r"service.*due",
                r"oil.*change",
                r"tire.*rotation",
                r"brake.*check",
                r"maintenance.*schedule"
            ],
            "booking_request": [
                r"book.*appointment",
                r"schedule.*service",
                r"find.*service.*center",
                r"make.*appointment",
                r"reserve.*slot"
            ],
            "emergency": [
                r"emergency",
                r"urgent",
                r"breakdown",
                r"accident",
                r"stuck",
                r"won.*start"
            ]
        }

    def _initialize_response_templates(self) -> Dict[str, str]:
        """Initialize response templates for fallback"""
        return {
            "vehicle_status": "Your {vehicle_make} {vehicle_model} currently has a health score of {health_score}. Let me check for any recent alerts or issues.",
            "maintenance_inquiry": "I can help you with maintenance information for your {vehicle_make} {vehicle_model}. What specific maintenance are you asking about?",
            "booking_request": "I'd be happy to help you schedule a service appointment. Let me find available service centers near you.",
            "emergency": "I understand this is urgent. For immediate roadside assistance, please call emergency services. I'm here to help with any vehicle diagnostics you need.",
            "general_inquiry": "Hello! I'm AIVONITY, your vehicle assistant. I can help with vehicle health monitoring, maintenance scheduling, and answering questions about your car. How can I assist you today?"
        }

    async def _update_conversation_context(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Update conversation context with new information"""
        try:
            user_id = payload.get("user_id")
            context_updates = payload.get("context_updates", {})
            
            if user_id in self.active_conversations:
                context = self.active_conversations[user_id]
                
                # Update context data
                for key, value in context_updates.items():
                    context.context_data[key] = value
                
                # Update vehicle_id if provided
                if "vehicle_id" in context_updates:
                    context.vehicle_id = context_updates["vehicle_id"]
                
                self.logger.info(f"✅ Updated conversation context for user {user_id}")
                
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="websocket_manager",
                    message_type="context_updated",
                    payload={
                        "user_id": user_id,
                        "success": True,
                        "updated_fields": list(context_updates.keys())
                    },
                    correlation_id=correlation_id
                )
            else:
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="websocket_manager",
                    message_type="context_error",
                    payload={
                        "user_id": user_id,
                        "error": "No active conversation found"
                    },
                    correlation_id=correlation_id
                )
                
        except Exception as e:
            self.logger.error(f"❌ Error updating conversation context: {e}")
            raise

    async def _get_conversation_history(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Get conversation history for a user"""
        try:
            user_id = payload.get("user_id")
            limit = payload.get("limit", 20)
            
            if user_id in self.active_conversations:
                context = self.active_conversations[user_id]
                history = context.conversation_history[-limit:] if context.conversation_history else []
                
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="websocket_manager",
                    message_type="conversation_history",
                    payload={
                        "user_id": user_id,
                        "history": history,
                        "total_messages": len(context.conversation_history)
                    },
                    correlation_id=correlation_id
                )
            else:
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="websocket_manager",
                    message_type="conversation_history",
                    payload={
                        "user_id": user_id,
                        "history": [],
                        "total_messages": 0
                    },
                    correlation_id=correlation_id
                )
                
        except Exception as e:
            self.logger.error(f"❌ Error getting conversation history: {e}")
            raise

    async def _handle_emergency(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Handle emergency situations with priority response"""
        try:
            user_id = payload.get("user_id")
            emergency_type = payload.get("emergency_type", "general")
            location = payload.get("location")
            vehicle_id = payload.get("vehicle_id")
            
            # Get emergency response based on type
            emergency_responses = {
                "breakdown": "I understand you're experiencing a vehicle breakdown. For immediate roadside assistance, please call emergency services at your local number. I'm checking your vehicle's last known status to help diagnose the issue.",
                "accident": "If you're in an accident, please ensure your safety first and call emergency services immediately. I'm here to help with any vehicle information you might need for insurance or towing services.",
                "stuck": "I see you're stuck. Please stay calm and ensure your safety. I can help you find nearby towing services or provide guidance based on your vehicle's condition.",
                "general": "I understand this is an emergency situation. Please prioritize your safety and call emergency services if needed. I'm here to assist with any vehicle-related information."
            }
            
            emergency_response = emergency_responses.get(emergency_type, emergency_responses["general"])
            
            # Add location-specific guidance if available
            if location:
                emergency_response += f" Your current location appears to be near {location.get('address', 'your reported location')}."
            
            # Get vehicle context for additional help
            vehicle_context = ""
            if vehicle_id:
                vehicle_data = await self._get_vehicle_context(vehicle_id)
                if vehicle_data:
                    emergency_response += f" Your {vehicle_data.get('make', '')} {vehicle_data.get('model', '')} shows a health score of {vehicle_data.get('health_score', 'N/A')}."
            
            # Log emergency for monitoring
            self.logger.warning(f"🚨 Emergency detected for user {user_id}: {emergency_type}")
            
            return AgentMessage(
                sender=self.agent_name,
                recipient="websocket_manager",
                message_type="emergency_response",
                payload={
                    "user_id": user_id,
                    "response": emergency_response,
                    "emergency_type": emergency_type,
                    "priority": "critical",
                    "suggested_actions": [
                        "Call emergency services if in immediate danger",
                        "Move to a safe location if possible",
                        "Contact roadside assistance",
                        "Document the situation with photos if safe to do so"
                    ]
                },
                priority=4,  # Critical priority
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error handling emergency: {e}")
            raise

    async def _context_cleanup_loop(self):
        """Clean up expired conversation contexts"""
        while self.is_running:
            try:
                current_time = datetime.utcnow()
                expired_contexts = []
                
                for user_id, context in self.active_conversations.items():
                    if context.conversation_history:
                        last_message_time = datetime.fromisoformat(
                            context.conversation_history[-1]["timestamp"].replace('Z', '+00:00')
                        )
                        if (current_time - last_message_time).total_seconds() > self.conversation_timeout:
                            expired_contexts.append(user_id)
                
                # Remove expired contexts
                for user_id in expired_contexts:
                    del self.active_conversations[user_id]
                    self.logger.debug(f"🧹 Cleaned up expired conversation context for user {user_id}")
                
                await asyncio.sleep(self.context_cleanup_interval)
                
            except Exception as e:
                self.logger.error(f"❌ Error in context cleanup: {e}")
                await asyncio.sleep(60)

    async def health_check(self) -> Dict[str, Any]:
        """Perform comprehensive health check"""
        try:
            health_status = {
                "healthy": True,
                "timestamp": datetime.utcnow().isoformat(),
                "ai_services": {
                    "openai_available": self.openai_client is not None,
                    "anthropic_available": self.anthropic_client is not None,
                    "current_provider": self.ai_provider
                },
                "conversation_metrics": {
                    "active_conversations": len(self.active_conversations),
                    "voice_enabled": self.voice_enabled,
                    "supported_languages": self.supported_languages
                },
                "performance": {
                    "messages_processed": self.metrics.messages_processed,
                    "average_response_time": self.metrics.average_processing_time
                }
            }
            
            # Check if at least one AI service is available
            if not self.openai_client and not self.anthropic_client:
                health_status["healthy"] = False
                health_status["issues"] = ["No AI service configured"]
            
            return health_status
            
        except Exception as e:
            self.logger.error(f"❌ Error in health check: {e}")
            return {
                "healthy": False,
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e)
            }