"""
AIVONITY Voice Processing Service
Advanced speech-to-text and text-to-speech capabilities
"""

import asyncio
import io
import tempfile
import os
from typing import Optional, Dict, Any, List
from datetime import datetime
import aiofiles
import aiohttp
from pydub import AudioSegment
import speech_recognition as sr
from gtts import gTTS
import openai

from app.config import settings
from app.utils.logging_config import get_logger

class VoiceService:
    """
    Advanced voice processing service for speech-to-text and text-to-speech
    Supports multiple providers and languages
    """
    
    def __init__(self):
        self.logger = get_logger("voice_service")
        
        # Speech Recognition
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        
        # Supported formats and configurations
        self.supported_formats = ['.wav', '.mp3', '.m4a', '.ogg', '.flac']
        self.target_sample_rate = settings.VOICE_SAMPLE_RATE
        self.max_duration = settings.VOICE_MAX_DURATION
        
        # Language configurations
        self.language_codes = {
            'en': 'en-US',
            'hi': 'hi-IN',
            'es': 'es-ES',
            'fr': 'fr-FR',
            'de': 'de-DE',
            'it': 'it-IT',
            'pt': 'pt-BR',
            'ru': 'ru-RU',
            'ja': 'ja-JP',
            'ko': 'ko-KR',
            'zh': 'zh-CN'
        }
        
        # TTS Voice mappings
        self.tts_voices = {
            'en': {'gtts': 'en', 'openai': 'alloy'},
            'hi': {'gtts': 'hi', 'openai': 'nova'},
            'es': {'gtts': 'es', 'openai': 'shimmer'},
            'fr': {'gtts': 'fr', 'openai': 'echo'},
            'de': {'gtts': 'de', 'openai': 'fable'},
            'it': {'gtts': 'it', 'openai': 'onyx'}
        }
        
        # Initialize OpenAI client if available
        self.openai_client = None
        if settings.OPENAI_API_KEY:
            self.openai_client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

    async def speech_to_text(self, audio_data: bytes, language: str = 'en', 
                           provider: str = 'auto') -> Dict[str, Any]:
        """
        Convert speech to text using various providers
        
        Args:
            audio_data: Raw audio bytes
            language: Language code (e.g., 'en', 'hi')
            provider: STT provider ('openai', 'google', 'auto')
            
        Returns:
            Dict with transcription results and metadata
        """
        try:
            start_time = datetime.utcnow()
            
            # Preprocess audio
            processed_audio = await self._preprocess_audio(audio_data)
            if not processed_audio:
                return {
                    'success': False,
                    'error': 'Audio preprocessing failed',
                    'transcription': None
                }
            
            # Choose provider
            if provider == 'auto':
                provider = 'openai' if self.openai_client else 'google'
            
            # Perform transcription
            transcription_result = None
            
            if provider == 'openai' and self.openai_client:
                transcription_result = await self._openai_speech_to_text(processed_audio, language)
            elif provider == 'google':
                transcription_result = await self._google_speech_to_text(processed_audio, language)
            else:
                return {
                    'success': False,
                    'error': f'Provider {provider} not available',
                    'transcription': None
                }
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            return {
                'success': True,
                'transcription': transcription_result.get('text', ''),
                'confidence': transcription_result.get('confidence', 0.0),
                'language': language,
                'provider': provider,
                'processing_time': processing_time,
                'metadata': {
                    'audio_duration': transcription_result.get('duration', 0),
                    'detected_language': transcription_result.get('detected_language'),
                    'timestamp': start_time.isoformat()
                }
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in speech-to-text: {e}")
            return {
                'success': False,
                'error': str(e),
                'transcription': None
            }

    async def text_to_speech(self, text: str, language: str = 'en', 
                           provider: str = 'auto', voice: Optional[str] = None) -> Dict[str, Any]:
        """
        Convert text to speech using various providers
        
        Args:
            text: Text to convert to speech
            language: Language code
            provider: TTS provider ('openai', 'gtts', 'auto')
            voice: Specific voice to use
            
        Returns:
            Dict with audio data and metadata
        """
        try:
            start_time = datetime.utcnow()
            
            # Validate input
            if not text or len(text.strip()) == 0:
                return {
                    'success': False,
                    'error': 'Empty text provided',
                    'audio_data': None
                }
            
            # Limit text length
            if len(text) > 4000:  # Reasonable limit for TTS
                text = text[:4000] + "..."
            
            # Choose provider
            if provider == 'auto':
                provider = 'openai' if self.openai_client else 'gtts'
            
            # Generate speech
            audio_result = None
            
            if provider == 'openai' and self.openai_client:
                audio_result = await self._openai_text_to_speech(text, language, voice)
            elif provider == 'gtts':
                audio_result = await self._gtts_text_to_speech(text, language)
            else:
                return {
                    'success': False,
                    'error': f'Provider {provider} not available',
                    'audio_data': None
                }
            
            processing_time = (datetime.utcnow() - start_time).total_seconds()
            
            return {
                'success': True,
                'audio_data': audio_result.get('audio_data'),
                'format': audio_result.get('format', 'mp3'),
                'language': language,
                'provider': provider,
                'voice': voice or audio_result.get('voice'),
                'processing_time': processing_time,
                'metadata': {
                    'text_length': len(text),
                    'audio_duration': audio_result.get('duration'),
                    'timestamp': start_time.isoformat()
                }
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in text-to-speech: {e}")
            return {
                'success': False,
                'error': str(e),
                'audio_data': None
            }

    async def _preprocess_audio(self, audio_data: bytes) -> Optional[bytes]:
        """Preprocess audio data for optimal recognition"""
        try:
            # Create temporary file for processing
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_path = temp_file.name
            
            try:
                # Load audio with pydub
                audio = AudioSegment.from_file(temp_path)
                
                # Convert to mono if stereo
                if audio.channels > 1:
                    audio = audio.set_channels(1)
                
                # Set sample rate
                if audio.frame_rate != self.target_sample_rate:
                    audio = audio.set_frame_rate(self.target_sample_rate)
                
                # Normalize audio levels
                audio = audio.normalize()
                
                # Limit duration
                if len(audio) > self.max_duration * 1000:  # pydub uses milliseconds
                    audio = audio[:self.max_duration * 1000]
                
                # Export processed audio
                processed_buffer = io.BytesIO()
                audio.export(processed_buffer, format="wav")
                processed_data = processed_buffer.getvalue()
                
                return processed_data
                
            finally:
                # Clean up temporary file
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
            
        except Exception as e:
            self.logger.error(f"❌ Error preprocessing audio: {e}")
            return None

    async def _openai_speech_to_text(self, audio_data: bytes, language: str) -> Dict[str, Any]:
        """Use OpenAI Whisper for speech-to-text"""
        try:
            # Create temporary file for OpenAI API
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_path = temp_file.name
            
            try:
                # Use OpenAI Whisper API
                with open(temp_path, 'rb') as audio_file:
                    response = await self.openai_client.audio.transcriptions.create(
                        model="whisper-1",
                        file=audio_file,
                        language=language if language in ['en', 'hi', 'es', 'fr', 'de'] else None,
                        response_format="verbose_json"
                    )
                
                return {
                    'text': response.text,
                    'confidence': 0.9,  # OpenAI doesn't provide confidence scores
                    'duration': response.duration if hasattr(response, 'duration') else 0,
                    'detected_language': response.language if hasattr(response, 'language') else language
                }
                
            finally:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
            
        except Exception as e:
            self.logger.error(f"❌ Error in OpenAI speech-to-text: {e}")
            raise

    async def _google_speech_to_text(self, audio_data: bytes, language: str) -> Dict[str, Any]:
        """Use Google Speech Recognition for speech-to-text"""
        try:
            # Create temporary file
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_path = temp_file.name
            
            try:
                # Use speech_recognition library with Google API
                with sr.AudioFile(temp_path) as source:
                    audio = self.recognizer.record(source)
                
                # Get language code
                lang_code = self.language_codes.get(language, 'en-US')
                
                # Perform recognition
                text = self.recognizer.recognize_google(audio, language=lang_code)
                
                return {
                    'text': text,
                    'confidence': 0.8,  # Estimated confidence
                    'duration': len(audio.frame_data) / audio.sample_rate,
                    'detected_language': language
                }
                
            finally:
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
            
        except sr.UnknownValueError:
            return {
                'text': '',
                'confidence': 0.0,
                'duration': 0,
                'detected_language': language
            }
        except Exception as e:
            self.logger.error(f"❌ Error in Google speech-to-text: {e}")
            raise

    async def _openai_text_to_speech(self, text: str, language: str, voice: Optional[str] = None) -> Dict[str, Any]:
        """Use OpenAI TTS for text-to-speech"""
        try:
            # Select voice
            if not voice:
                voice = self.tts_voices.get(language, {}).get('openai', 'alloy')
            
            # Generate speech
            response = await self.openai_client.audio.speech.create(
                model="tts-1",
                voice=voice,
                input=text,
                response_format="mp3"
            )
            
            return {
                'audio_data': response.content,
                'format': 'mp3',
                'voice': voice,
                'duration': None  # OpenAI doesn't provide duration
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in OpenAI text-to-speech: {e}")
            raise

    async def _gtts_text_to_speech(self, text: str, language: str) -> Dict[str, Any]:
        """Use Google Text-to-Speech for text-to-speech"""
        try:
            # Get language code for gTTS
            gtts_lang = self.tts_voices.get(language, {}).get('gtts', 'en')
            
            # Generate speech
            tts = gTTS(text=text, lang=gtts_lang, slow=False)
            
            # Save to buffer
            audio_buffer = io.BytesIO()
            tts.write_to_fp(audio_buffer)
            audio_data = audio_buffer.getvalue()
            
            return {
                'audio_data': audio_data,
                'format': 'mp3',
                'voice': f'gtts_{gtts_lang}',
                'duration': None  # gTTS doesn't provide duration
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error in gTTS text-to-speech: {e}")
            raise

    async def detect_language(self, audio_data: bytes) -> Dict[str, Any]:
        """Detect language from audio data"""
        try:
            if self.openai_client:
                # Use OpenAI Whisper for language detection
                with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                    temp_file.write(audio_data)
                    temp_path = temp_file.name
                
                try:
                    with open(temp_path, 'rb') as audio_file:
                        response = await self.openai_client.audio.transcriptions.create(
                            model="whisper-1",
                            file=audio_file,
                            response_format="verbose_json"
                        )
                    
                    detected_language = getattr(response, 'language', 'en')
                    confidence = 0.9  # OpenAI Whisper is generally reliable
                    
                    return {
                        'success': True,
                        'language': detected_language,
                        'confidence': confidence,
                        'supported': detected_language in self.language_codes
                    }
                    
                finally:
                    if os.path.exists(temp_path):
                        os.unlink(temp_path)
            
            # Fallback: assume English
            return {
                'success': True,
                'language': 'en',
                'confidence': 0.5,
                'supported': True
            }
            
        except Exception as e:
            self.logger.error(f"❌ Error detecting language: {e}")
            return {
                'success': False,
                'error': str(e),
                'language': 'en',
                'confidence': 0.0
            }

    def get_supported_languages(self) -> List[Dict[str, str]]:
        """Get list of supported languages"""
        return [
            {'code': code, 'name': name, 'native_name': native}
            for code, (name, native) in {
                'en': ('English', 'English'),
                'hi': ('Hindi', 'हिन्दी'),
                'es': ('Spanish', 'Español'),
                'fr': ('French', 'Français'),
                'de': ('German', 'Deutsch'),
                'it': ('Italian', 'Italiano'),
                'pt': ('Portuguese', 'Português'),
                'ru': ('Russian', 'Русский'),
                'ja': ('Japanese', '日本語'),
                'ko': ('Korean', '한국어'),
                'zh': ('Chinese', '中文')
            }.items()
            if code in self.language_codes
        ]

    async def validate_audio(self, audio_data: bytes) -> Dict[str, Any]:
        """Validate audio data for processing"""
        try:
            if not audio_data or len(audio_data) == 0:
                return {
                    'valid': False,
                    'error': 'Empty audio data'
                }
            
            # Check file size (max 25MB for most APIs)
            max_size = 25 * 1024 * 1024
            if len(audio_data) > max_size:
                return {
                    'valid': False,
                    'error': f'Audio file too large: {len(audio_data)} bytes (max: {max_size})'
                }
            
            # Try to load with pydub to validate format
            try:
                with tempfile.NamedTemporaryFile(delete=False) as temp_file:
                    temp_file.write(audio_data)
                    temp_path = temp_file.name
                
                audio = AudioSegment.from_file(temp_path)
                duration = len(audio) / 1000  # Convert to seconds
                
                # Clean up
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
                
                # Check duration
                if duration > self.max_duration:
                    return {
                        'valid': False,
                        'error': f'Audio too long: {duration}s (max: {self.max_duration}s)'
                    }
                
                return {
                    'valid': True,
                    'duration': duration,
                    'channels': audio.channels,
                    'sample_rate': audio.frame_rate,
                    'format': 'valid'
                }
                
            except Exception as format_error:
                return {
                    'valid': False,
                    'error': f'Invalid audio format: {format_error}'
                }
            
        except Exception as e:
            self.logger.error(f"❌ Error validating audio: {e}")
            return {
                'valid': False,
                'error': str(e)
            }

# Global voice service instance
voice_service = VoiceService()