"""
AIVONITY Chat API
AI-powered conversational interface endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from datetime import datetime
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
import uuid
import json

from app.db.database import get_db
from app.db.models import User, Vehicle, ChatSession
from app.api.auth import get_current_user
from app.agents.agent_manager import AgentManager
from app.agents.customer_agent import CustomerAgent
from app.services.voice_service import voice_service
from app.utils.logging_config import get_logger
from app.config import settings

logger = get_logger(__name__)
router = APIRouter()

# Pydantic models
class ChatMessage(BaseModel):
    message: str
    session_id: Optional[str] = None
    is_voice: bool = False
    language: str = "en"
    context: Optional[Dict[str, Any]] = None

class ChatResponse(BaseModel):
    message_id: str
    response: str
    session_id: str
    timestamp: datetime
    agent: str
    confidence: Optional[float] = None
    suggestions: Optional[List[str]] = None
    context: Optional[Dict[str, Any]] = None

class ChatHistory(BaseModel):
    session_id: str
    messages: List[Dict[str, Any]]
    created_at: datetime
    last_activity: datetime
    message_count: int

class VoiceMessage(BaseModel):
    audio_data: str  # Base64 encoded audio
    session_id: Optional[str] = None
    language: str = "en"
    format: str = "wav"

class VoiceResponse(BaseModel):
    message_id: str
    transcribed_text: str
    response_text: str
    audio_response: Optional[str] = None  # Base64 encoded audio response
    session_id: str
    timestamp: datetime
    language: str
    processing_time: float

# Dependency to get agent manager
async def get_agent_manager() -> AgentManager:
    """Get agent manager instance"""
    return AgentManager()

@router.post("/message", response_model=ChatResponse)
async def send_chat_message(
    message: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    agent_manager: AgentManager = Depends(get_agent_manager)
):
    """Send a text message to the AI assistant"""
    try:
        # Get or create chat session
        session_id = message.session_id or str(uuid.uuid4())
        
        # Get existing session or create new one
        if message.session_id:
            result = await db.execute(
                select(ChatSession).where(
                    and_(
                        ChatSession.id == message.session_id,
                        ChatSession.user_id == current_user.id
                    )
                )
            )
            chat_session = result.scalar_one_or_none()
        else:
            chat_session = None
        
        if not chat_session:
            # Create new session
            chat_session = ChatSession(
                id=session_id,
                user_id=current_user.id,
                session_type="text" if not message.is_voice else "voice",
                language=message.language,
                ai_model="aivonity_assistant",
                messages=[],
                context=message.context or {}
            )
            db.add(chat_session)
        
        # Add user message to session
        user_message = {
            "id": str(uuid.uuid4()),
            "role": "user",
            "content": message.message,
            "timestamp": datetime.utcnow().isoformat(),
            "is_voice": message.is_voice
        }
        
        chat_session.messages.append(user_message)
        
        # Get AI response
        ai_response = await get_ai_response(
            message.message,
            chat_session,
            current_user,
            agent_manager
        )
        
        # Add AI response to session
        ai_message = {
            "id": str(uuid.uuid4()),
            "role": "assistant",
            "content": ai_response["response"],
            "timestamp": datetime.utcnow().isoformat(),
            "confidence": ai_response.get("confidence"),
            "suggestions": ai_response.get("suggestions", [])
        }
        
        chat_session.messages.append(ai_message)
        chat_session.total_tokens += len(message.message.split()) + len(ai_response["response"].split())
        
        await db.commit()
        await db.refresh(chat_session)
        
        logger.info(f"💬 Chat message processed for user {current_user.email}")
        
        return ChatResponse(
            message_id=ai_message["id"],
            response=ai_response["response"],
            session_id=session_id,
            timestamp=datetime.utcnow(),
            agent="aivonity_assistant",
            confidence=ai_response.get("confidence"),
            suggestions=ai_response.get("suggestions"),
            context=ai_response.get("context")
        )
        
    except Exception as e:
        logger.error(f"Error processing chat message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process chat message"
        )

@router.post("/voice", response_model=VoiceResponse)
async def send_voice_message(
    voice_message: VoiceMessage,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    agent_manager: AgentManager = Depends(get_agent_manager)
):
    """Send a voice message to the AI assistant with full voice processing"""
    try:
        import base64
        from datetime import datetime
        
        start_time = datetime.utcnow()
        session_id = voice_message.session_id or str(uuid.uuid4())
        
        # Decode audio data
        try:
            audio_bytes = base64.b64decode(voice_message.audio_data)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid audio data encoding: {e}"
            )
        
        # Validate audio
        validation_result = await voice_service.validate_audio(audio_bytes)
        if not validation_result['valid']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid audio: {validation_result['error']}"
            )
        
        # Convert speech to text
        stt_result = await voice_service.speech_to_text(
            audio_bytes, 
            voice_message.language
        )
        
        if not stt_result['success']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Speech recognition failed: {stt_result.get('error', 'Unknown error')}"
            )
        
        transcribed_text = stt_result['transcription']
        
        if not transcribed_text or len(transcribed_text.strip()) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No speech detected in audio"
            )
        
        # Get or create chat session
        if voice_message.session_id:
            result = await db.execute(
                select(ChatSession).where(
                    and_(
                        ChatSession.id == voice_message.session_id,
                        ChatSession.user_id == current_user.id
                    )
                )
            )
            chat_session = result.scalar_one_or_none()
        else:
            chat_session = None
        
        if not chat_session:
            chat_session = ChatSession(
                id=session_id,
                user_id=current_user.id,
                session_type="voice",
                language=voice_message.language,
                ai_model="aivonity_assistant",
                messages=[],
                context={}
            )
            db.add(chat_session)
        
        # Add user message to session
        user_message = {
            "id": str(uuid.uuid4()),
            "role": "user",
            "content": transcribed_text,
            "timestamp": datetime.utcnow().isoformat(),
            "is_voice": True,
            "audio_metadata": {
                "duration": stt_result.get('metadata', {}).get('audio_duration', 0),
                "confidence": stt_result.get('confidence', 0),
                "language": voice_message.language
            }
        }
        
        chat_session.messages.append(user_message)
        
        # Get AI response using Customer Agent
        ai_response = await get_ai_response(
            transcribed_text,
            chat_session,
            current_user,
            agent_manager
        )
        
        response_text = ai_response["response"]
        
        # Convert response to speech
        tts_result = await voice_service.text_to_speech(
            response_text,
            voice_message.language
        )
        
        audio_response_b64 = None
        if tts_result['success']:
            audio_response_b64 = base64.b64encode(tts_result['audio_data']).decode('utf-8')
        
        # Add AI response to session
        ai_message = {
            "id": str(uuid.uuid4()),
            "role": "assistant",
            "content": response_text,
            "timestamp": datetime.utcnow().isoformat(),
            "is_voice": True,
            "confidence": ai_response.get("confidence"),
            "suggestions": ai_response.get("suggestions", []),
            "audio_metadata": {
                "tts_success": tts_result['success'] if tts_result else False,
                "language": voice_message.language
            }
        }
        
        chat_session.messages.append(ai_message)
        chat_session.total_tokens += len(transcribed_text.split()) + len(response_text.split())
        
        await db.commit()
        await db.refresh(chat_session)
        
        processing_time = (datetime.utcnow() - start_time).total_seconds()
        
        logger.info(f"🎤 Voice message processed for user {current_user.email} in {processing_time:.2f}s")
        
        return VoiceResponse(
            message_id=ai_message["id"],
            transcribed_text=transcribed_text,
            response_text=response_text,
            audio_response=audio_response_b64,
            session_id=session_id,
            timestamp=datetime.utcnow(),
            language=voice_message.language,
            processing_time=processing_time
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing voice message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to process voice message"
        )

@router.get("/history/{session_id}", response_model=ChatHistory)
async def get_chat_history(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get chat history for a specific session"""
    try:
        result = await db.execute(
            select(ChatSession).where(
                and_(
                    ChatSession.id == session_id,
                    ChatSession.user_id == current_user.id
                )
            )
        )
        chat_session = result.scalar_one_or_none()
        
        if not chat_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        return ChatHistory(
            session_id=session_id,
            messages=chat_session.messages,
            created_at=chat_session.created_at,
            last_activity=chat_session.updated_at,
            message_count=len(chat_session.messages)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving chat history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve chat history"
        )

@router.get("/sessions", response_model=List[Dict[str, Any]])
async def get_chat_sessions(
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's chat sessions"""
    try:
        result = await db.execute(
            select(ChatSession).where(ChatSession.user_id == current_user.id)
            .order_by(ChatSession.updated_at.desc())
            .limit(limit)
        )
        sessions = result.scalars().all()
        
        session_list = []
        for session in sessions:
            # Get last message for preview
            last_message = session.messages[-1] if session.messages else None
            
            session_info = {
                "session_id": str(session.id),
                "session_type": session.session_type,
                "language": session.language,
                "created_at": session.created_at.isoformat(),
                "last_activity": session.updated_at.isoformat(),
                "message_count": len(session.messages),
                "last_message": last_message["content"] if last_message else None,
                "is_active": session.is_active
            }
            session_list.append(session_info)
        
        return session_list
        
    except Exception as e:
        logger.error(f"Error retrieving chat sessions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve chat sessions"
        )

@router.delete("/session/{session_id}")
async def delete_chat_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a chat session"""
    try:
        result = await db.execute(
            select(ChatSession).where(
                and_(
                    ChatSession.id == session_id,
                    ChatSession.user_id == current_user.id
                )
            )
        )
        chat_session = result.scalar_one_or_none()
        
        if not chat_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Chat session not found"
            )
        
        await db.delete(chat_session)
        await db.commit()
        
        logger.info(f"🗑️ Chat session deleted: {session_id}")
        
        return {"message": "Chat session deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting chat session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete chat session"
        )

@router.post("/voice/detect-language")
async def detect_voice_language(
    voice_message: VoiceMessage,
    current_user: User = Depends(get_current_user)
):
    """Detect language from voice audio"""
    try:
        import base64
        
        # Decode audio data
        try:
            audio_bytes = base64.b64decode(voice_message.audio_data)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid audio data encoding: {e}"
            )
        
        # Validate audio
        validation_result = await voice_service.validate_audio(audio_bytes)
        if not validation_result['valid']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid audio: {validation_result['error']}"
            )
        
        # Detect language
        detection_result = await voice_service.detect_language(audio_bytes)
        
        if not detection_result['success']:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Language detection failed: {detection_result.get('error', 'Unknown error')}"
            )
        
        logger.info(f"🌐 Language detected for user {current_user.email}: {detection_result['language']}")
        
        return {
            "detected_language": detection_result['language'],
            "confidence": detection_result['confidence'],
            "supported": detection_result['supported'],
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error detecting language: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to detect language"
        )

@router.get("/voice/languages")
async def get_supported_languages():
    """Get list of supported languages for voice interaction"""
    try:
        languages = voice_service.get_supported_languages()
        
        return {
            "supported_languages": languages,
            "default_language": "en",
            "total_count": len(languages),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error getting supported languages: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get supported languages"
        )

@router.post("/voice/validate")
async def validate_voice_audio(
    voice_message: VoiceMessage,
    current_user: User = Depends(get_current_user)
):
    """Validate voice audio before processing"""
    try:
        import base64
        
        # Decode audio data
        try:
            audio_bytes = base64.b64decode(voice_message.audio_data)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid audio data encoding: {e}"
            )
        
        # Validate audio
        validation_result = await voice_service.validate_audio(audio_bytes)
        
        return {
            "valid": validation_result['valid'],
            "error": validation_result.get('error'),
            "duration": validation_result.get('duration'),
            "channels": validation_result.get('channels'),
            "sample_rate": validation_result.get('sample_rate'),
            "format": validation_result.get('format'),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error validating audio: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to validate audio"
        )

# Utility functions
async def get_ai_response(
    message: str,
    chat_session: ChatSession,
    user: User,
    agent_manager: AgentManager
) -> Dict[str, Any]:
    """Get AI response for user message"""
    try:
        # Get user's vehicles for context
        from sqlalchemy.ext.asyncio import AsyncSession
        from app.db.database import AsyncSessionLocal
        
        async with AsyncSessionLocal() as db:
            vehicles_result = await db.execute(
                select(Vehicle).where(Vehicle.user_id == user.id)
            )
            vehicles = vehicles_result.scalars().all()
        
        # Build context
        context = {
            "user_name": user.name,
            "user_language": chat_session.language,
            "vehicles": [
                {
                    "id": str(v.id),
                    "make": v.make,
                    "model": v.model,
                    "year": v.year,
                    "health_score": v.health_score
                }
                for v in vehicles
            ],
            "conversation_history": chat_session.messages[-5:] if chat_session.messages else []
        }
        
        # Get Customer Agent from agent manager
        customer_agent = await agent_manager.get_agent("customer_agent")
        
        if customer_agent:
            # Create agent message for Customer Agent
            from app.agents.base_agent import AgentMessage
            
            agent_message = AgentMessage(
                sender="chat_api",
                recipient="customer_agent",
                message_type="chat_message",
                payload={
                    "user_id": str(user.id),
                    "message": message,
                    "vehicle_id": vehicles[0].id if vehicles else None,
                    "language": chat_session.language,
                    "context": context
                },
                correlation_id=str(chat_session.id)
            )
            
            # Process message through Customer Agent
            response_message = await customer_agent.process_message(agent_message)
            
            if response_message and response_message.payload:
                response_data = response_message.payload
            else:
                response_data = {"response": "I'm here to help with your vehicle needs!"}
        else:
            # Fallback if Customer Agent not available
            response_data = {"response": "I'm here to help with your vehicle needs!"}
        
        # Generate suggestions based on message content
        suggestions = generate_suggestions(message, vehicles)
        
        return {
            "response": response_data.get("response", "I'm here to help with your vehicle needs!"),
            "confidence": 0.85,
            "suggestions": suggestions,
            "context": context
        }
        
    except Exception as e:
        logger.error(f"Error getting AI response: {e}")
        return {
            "response": "I apologize, but I'm experiencing some technical difficulties. Please try again in a moment.",
            "confidence": 0.0,
            "suggestions": ["Try asking about vehicle health", "Check maintenance schedule", "View recent alerts"]
        }

def generate_suggestions(message: str, vehicles: List[Vehicle]) -> List[str]:
    """Generate contextual suggestions based on user message"""
    try:
        message_lower = message.lower()
        suggestions = []
        
        # Health-related suggestions
        if any(word in message_lower for word in ["health", "status", "condition", "check"]):
            suggestions.extend([
                "Show detailed health report",
                "View recent alerts",
                "Check component status"
            ])
        
        # Maintenance-related suggestions
        if any(word in message_lower for word in ["maintenance", "service", "repair", "fix"]):
            suggestions.extend([
                "Schedule maintenance",
                "View maintenance history",
                "Find nearby service centers"
            ])
        
        # Vehicle-specific suggestions
        if vehicles:
            vehicle_names = [f"{v.make} {v.model}" for v in vehicles[:2]]
            suggestions.extend([f"Check {name} status" for name in vehicle_names])
        
        # General suggestions
        if not suggestions:
            suggestions = [
                "Check vehicle health",
                "View maintenance schedule",
                "Find service centers",
                "Review recent trips"
            ]
        
        return suggestions[:4]  # Limit to 4 suggestions
        
    except Exception as e:
        logger.error(f"Error generating suggestions: {e}")
        return ["How can I help you today?"]