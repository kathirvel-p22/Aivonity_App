"""
AIVONITY Configuration Management
Advanced configuration with environment-based settings
"""

from pydantic_settings import BaseSettings
from typing import List, Optional
import os
from pathlib import Path

class Settings(BaseSettings):
    """Application settings with innovative configuration management"""
    
    # Application
    APP_NAME: str = "AIVONITY"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "development"
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "aivonity-super-secret-key-change-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    ALGORITHM: str = "HS256"
    
    # Database Configuration
    DATABASE_URL: str = "postgresql+asyncpg://aivonity:password@localhost:5432/aivonity"
    TIMESCALE_URL: str = "postgresql+asyncpg://aivonity:password@localhost:5432/aivonity"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 30
    
    # Redis Configuration
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_CACHE_TTL: int = 3600  # 1 hour
    
    # AI Services Configuration
    OPENAI_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None
    AI_MODEL_TEMPERATURE: float = 0.7
    AI_MAX_TOKENS: int = 2000
    
    # ML Model Configuration
    ML_MODEL_PATH: str = "data/models"
    ANOMALY_THRESHOLD: float = 0.7
    PREDICTION_CONFIDENCE_THRESHOLD: float = 0.8
    
    # Notification Services
    SENDGRID_API_KEY: Optional[str] = None
    TWILIO_ACCOUNT_SID: Optional[str] = None
    TWILIO_AUTH_TOKEN: Optional[str] = None
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    
    # WebSocket Configuration
    WEBSOCKET_HEARTBEAT_INTERVAL: int = 30
    MAX_WEBSOCKET_CONNECTIONS: int = 1000
    
    # Security Configuration
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://aivonity.app"
    ]
    CORS_ALLOW_CREDENTIALS: bool = True
    
    # Agent Configuration
    AGENT_HEARTBEAT_INTERVAL: int = 60
    AGENT_MAX_RETRIES: int = 3
    AGENT_TIMEOUT: int = 30
    
    # Performance Configuration
    MAX_TELEMETRY_BATCH_SIZE: int = 1000
    TELEMETRY_PROCESSING_INTERVAL: int = 5  # seconds
    PREDICTION_CACHE_TTL: int = 1800  # 30 minutes
    
    # Monitoring Configuration
    PROMETHEUS_ENABLED: bool = True
    SENTRY_DSN: Optional[str] = None
    LOG_LEVEL: str = "INFO"
    
    # File Storage
    UPLOAD_DIR: str = "uploads"
    MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_FILE_TYPES: List[str] = [".pdf", ".jpg", ".png", ".mp3", ".wav"]
    
    # Rate Limiting
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW: int = 60  # seconds
    
    # Telemetry Configuration
    TELEMETRY_RETENTION_DAYS: int = 365
    TELEMETRY_COMPRESSION_ENABLED: bool = True
    REAL_TIME_PROCESSING_ENABLED: bool = True
    
    # Service Center Integration
    SERVICE_CENTER_API_TIMEOUT: int = 30
    MAX_SERVICE_CENTER_DISTANCE: int = 50  # km
    
    # Voice Processing
    VOICE_SAMPLE_RATE: int = 16000
    VOICE_MAX_DURATION: int = 300  # 5 minutes
    SUPPORTED_LANGUAGES: List[str] = ["en", "hi"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Create global settings instance
settings = Settings()

# Ensure required directories exist
def create_directories():
    """Create necessary directories for the application"""
    directories = [
        settings.UPLOAD_DIR,
        settings.ML_MODEL_PATH,
        "logs",
        "data/raw",
        "data/processed"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)

# Initialize directories on import
create_directories()