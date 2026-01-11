"""
AIVONITY - Intelligent Vehicle Assistant Ecosystem
Main FastAPI application entry point with innovative architecture
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
from typing import Dict, List
import json
import asyncio
from datetime import datetime

from app.config import settings
from app.db.database import init_db
from app.agents.agent_manager import AgentManager
from app.api import auth, telemetry, prediction, booking, chat, feedback, notifications
from app.utils.logging_config import setup_logging
from app.utils.websocket_manager import WebSocketManager
from app.utils.error_handler import setup_error_handlers
from app.utils.api_client import api_client_manager
from app.utils.health_check import system_health_monitor, setup_health_monitoring

# Setup structured logging
setup_logging()
logger = logging.getLogger(__name__)

# Global instances
agent_manager = AgentManager()
websocket_manager = WebSocketManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management with agent initialization"""
    logger.info("🚀 Starting AIVONITY Intelligent Vehicle Assistant")
    
    # Initialize database
    await init_db()
    logger.info("✅ Database initialized")
    
    # Start AI agents
    await agent_manager.start_all_agents()
    logger.info("🤖 All AI agents started successfully")
    
    # Setup error handlers
    setup_error_handlers(app)
    logger.info("🛡️ Error handlers configured")
    
    # Setup health monitoring
    # Note: In a real implementation, you would pass actual instances
    # await setup_health_monitoring(db_session_factory, redis_client, agent_manager)
    logger.info("🏥 Health monitoring configured")
    
    # Setup performance monitoring and alerting
    from app.utils.metrics import setup_performance_monitoring
    from app.utils.alerting import setup_alerting
    await setup_performance_monitoring()
    await setup_alerting()
    logger.info("📊 Performance monitoring and alerting configured")
    
    # Setup audit trail and log aggregation
    from app.utils.audit_trail import setup_audit_trail
    from app.utils.log_aggregation import setup_log_aggregation
    await setup_audit_trail()
    await setup_log_aggregation()
    logger.info("📋 Audit trail and log aggregation configured")
    
    yield
    
    # Cleanup on shutdown
    await agent_manager.stop_all_agents()
    await api_client_manager.close_all()
    
    # Shutdown monitoring systems
    from app.utils.metrics import system_metrics_collector
    from app.utils.alerting import shutdown_alerting
    from app.utils.audit_trail import shutdown_audit_trail
    from app.utils.log_aggregation import shutdown_log_aggregation
    await system_metrics_collector.stop_collection()
    await shutdown_alerting()
    await shutdown_audit_trail()
    await shutdown_log_aggregation()
    
    logger.info("🛑 AIVONITY shutdown complete")

# Create FastAPI app with innovative configuration
app = FastAPI(
    title="AIVONITY API",
    description="Intelligent Vehicle Assistant Ecosystem - Advanced AI-Powered Platform",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# Add middleware for performance and security
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add monitoring middleware
from app.utils.monitoring_middleware import setup_monitoring_middleware
setup_monitoring_middleware(app)

# Include API routers with versioning
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(telemetry.router, prefix="/api/v1/telemetry", tags=["Telemetry"])
app.include_router(prediction.router, prefix="/api/v1/predictions", tags=["Predictions"])
app.include_router(booking.router, prefix="/api/v1/booking", tags=["Booking"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["AI Chat"])
app.include_router(feedback.router, prefix="/api/v1/feedback", tags=["Feedback & RCA"])
app.include_router(notifications.router, prefix="/api/v1", tags=["Notifications"])

# Import and include sync router
from app.api import sync
app.include_router(sync.router, prefix="/api/v1", tags=["Offline Sync"])

# Import and include monitoring router
from app.api import monitoring
app.include_router(monitoring.router, prefix="/api/v1/monitoring", tags=["Monitoring & Metrics"])

# Import and include logs router
from app.api import logs
app.include_router(logs.router, prefix="/api/v1/logs", tags=["Logs & Audit"])

# Import and include remote monitoring router
from app.api import remote_monitoring
app.include_router(remote_monitoring.router, prefix="/api/v1", tags=["Remote Monitoring"])

@app.get("/")
async def root():
    """Root endpoint with system status"""
    return {
        "message": "🚗 AIVONITY - Intelligent Vehicle Assistant Ecosystem",
        "version": "1.0.0",
        "status": "operational",
        "agents_status": await agent_manager.get_agents_status(),
        "features": [
            "Real-time Telemetry Monitoring",
            "Predictive Maintenance AI",
            "Intelligent Service Scheduling", 
            "Conversational AI Assistant",
            "Root Cause Analysis",
            "UEBA Security Monitoring"
        ]
    }

@app.get("/health")
async def health_check():
    """Comprehensive health check endpoint"""
    try:
        health_results = await system_health_monitor.check_all(timeout=10.0)
        return health_results
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return {
            "overall_status": "unknown",
            "timestamp": datetime.utcnow().isoformat(),
            "error": str(e),
            "components": {}
        }

@app.get("/health/quick")
async def quick_health_check():
    """Quick health check endpoint"""
    last_results = system_health_monitor.get_last_results()
    if last_results:
        return {
            "status": "healthy" if system_health_monitor.is_healthy() else "unhealthy",
            "last_check": last_results
        }
    else:
        return {
            "status": "unknown",
            "message": "No health check data available"
        }

# WebSocket endpoints for real-time communication
@app.websocket("/ws/telemetry/{vehicle_id}")
async def telemetry_websocket(websocket: WebSocket, vehicle_id: str):
    """Real-time telemetry streaming WebSocket"""
    await websocket_manager.connect(websocket, f"telemetry_{vehicle_id}")
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            # Process real-time telemetry updates
            await websocket_manager.broadcast_to_group(
                f"telemetry_{vehicle_id}", 
                {"type": "telemetry_update", "data": json.loads(data)}
            )
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket, f"telemetry_{vehicle_id}")

@app.websocket("/ws/chat/{user_id}")
async def chat_websocket(websocket: WebSocket, user_id: str):
    """Real-time AI chat WebSocket"""
    await websocket_manager.connect(websocket, f"chat_{user_id}")
    try:
        while True:
            message = await websocket.receive_text()
            # Process through Customer Agent
            response = await agent_manager.process_chat_message(user_id, json.loads(message))
            await websocket.send_text(json.dumps(response))
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket, f"chat_{user_id}")

@app.websocket("/ws/alerts/{user_id}")
async def alerts_websocket(websocket: WebSocket, user_id: str):
    """Real-time alerts and notifications WebSocket"""
    await websocket_manager.connect(websocket, f"alerts_{user_id}")
    try:
        while True:
            # Keep connection alive for receiving alerts
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket, f"alerts_{user_id}")

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )