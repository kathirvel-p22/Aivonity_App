"""
AIVONITY Base Agent Architecture
Advanced AI agent framework with innovative capabilities
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, List
import asyncio
import logging
import time
import uuid
from datetime import datetime
from dataclasses import dataclass, field
import json

from app.config import settings
from app.utils.logging_config import get_logger

@dataclass
class AgentMessage:
    """Standardized message format for agent communication"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    sender: str = ""
    recipient: str = ""
    message_type: str = "data"
    payload: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.utcnow)
    priority: int = 1  # 1=low, 2=medium, 3=high, 4=critical
    correlation_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "sender": self.sender,
            "recipient": self.recipient,
            "message_type": self.message_type,
            "payload": self.payload,
            "timestamp": self.timestamp.isoformat(),
            "priority": self.priority,
            "correlation_id": self.correlation_id
        }

@dataclass
class AgentMetrics:
    """Agent performance and health metrics"""
    messages_processed: int = 0
    messages_failed: int = 0
    average_processing_time: float = 0.0
    last_activity: Optional[datetime] = None
    memory_usage: float = 0.0
    cpu_usage: float = 0.0
    error_rate: float = 0.0
    uptime: float = 0.0
    
    def update_processing_time(self, processing_time: float):
        """Update average processing time with new measurement"""
        if self.messages_processed == 0:
            self.average_processing_time = processing_time
        else:
            total_time = self.average_processing_time * self.messages_processed
            self.messages_processed += 1
            self.average_processing_time = (total_time + processing_time) / self.messages_processed
        
        self.last_activity = datetime.utcnow()

class BaseAgent(ABC):
    """
    Advanced base class for all AIVONITY AI agents
    Provides comprehensive framework for agent development
    """
    
    def __init__(self, agent_name: str, config: Dict[str, Any]):
        self.agent_name = agent_name
        self.config = config
        self.logger = get_logger(f"agent.{agent_name}")
        
        # Agent state
        self.is_running = False
        self.is_healthy = True
        self.start_time = None
        
        # Metrics and monitoring
        self.metrics = AgentMetrics()
        self.message_queue = asyncio.Queue()
        self.response_callbacks = {}
        
        # Agent capabilities
        self.capabilities = self._define_capabilities()
        self.version = "1.0.0"
        
        # Error handling
        self.max_retries = config.get("max_retries", settings.AGENT_MAX_RETRIES)
        self.timeout = config.get("timeout", settings.AGENT_TIMEOUT)
        
        self.logger.info(f"🤖 Agent {self.agent_name} initialized with capabilities: {self.capabilities}")

    @abstractmethod
    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """
        Process incoming message and return response if needed
        Must be implemented by all agents
        """
        pass

    @abstractmethod
    async def health_check(self) -> Dict[str, Any]:
        """
        Perform health check and return status
        Must be implemented by all agents
        """
        pass

    @abstractmethod
    def _define_capabilities(self) -> List[str]:
        """
        Define agent capabilities
        Must be implemented by all agents
        """
        pass

    async def start(self):
        """Start the agent and begin processing messages"""
        if self.is_running:
            self.logger.warning(f"Agent {self.agent_name} is already running")
            return
        
        self.is_running = True
        self.start_time = datetime.utcnow()
        self.logger.info(f"🚀 Starting agent {self.agent_name}")
        
        # Start message processing loop
        asyncio.create_task(self._message_processing_loop())
        
        # Start health monitoring
        asyncio.create_task(self._health_monitoring_loop())
        
        # Perform startup initialization
        await self._startup_initialization()

    async def stop(self):
        """Stop the agent gracefully"""
        self.logger.info(f"🛑 Stopping agent {self.agent_name}")
        self.is_running = False
        
        # Perform cleanup
        await self._cleanup()

    async def send_message(self, recipient: str, message_type: str, payload: Dict[str, Any], 
                          priority: int = 1, correlation_id: Optional[str] = None) -> str:
        """Send message to another agent or service"""
        message = AgentMessage(
            sender=self.agent_name,
            recipient=recipient,
            message_type=message_type,
            payload=payload,
            priority=priority,
            correlation_id=correlation_id
        )
        
        # Log outgoing message
        self.logger.debug(f"📤 Sending message to {recipient}: {message_type}")
        
        # Here you would implement actual message sending (Redis pub/sub, etc.)
        # For now, we'll just log it
        await self._log_agent_activity("message_sent", {
            "recipient": recipient,
            "message_type": message_type,
            "message_id": message.id
        })
        
        return message.id

    async def receive_message(self, message: AgentMessage):
        """Receive and queue message for processing"""
        await self.message_queue.put(message)
        self.logger.debug(f"📥 Received message from {message.sender}: {message.message_type}")

    async def _message_processing_loop(self):
        """Main message processing loop"""
        while self.is_running:
            try:
                # Get message from queue with timeout
                message = await asyncio.wait_for(
                    self.message_queue.get(), 
                    timeout=1.0
                )
                
                # Process message with timing
                start_time = time.time()
                
                try:
                    response = await self._process_message_with_retry(message)
                    processing_time = time.time() - start_time
                    
                    # Update metrics
                    self.metrics.update_processing_time(processing_time)
                    
                    # Send response if generated
                    if response:
                        await self._send_response(response)
                    
                    # Log successful processing
                    await self._log_agent_activity("message_processed", {
                        "message_id": message.id,
                        "processing_time": processing_time,
                        "success": True
                    })
                    
                except Exception as e:
                    self.metrics.messages_failed += 1
                    self.logger.error(f"❌ Failed to process message {message.id}: {e}")
                    
                    await self._log_agent_activity("message_failed", {
                        "message_id": message.id,
                        "error": str(e),
                        "success": False
                    })
                
            except asyncio.TimeoutError:
                # No message received, continue loop
                continue
            except Exception as e:
                self.logger.error(f"❌ Error in message processing loop: {e}")
                await asyncio.sleep(1)

    async def _process_message_with_retry(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process message with retry logic"""
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                return await asyncio.wait_for(
                    self.process_message(message),
                    timeout=self.timeout
                )
            except Exception as e:
                last_exception = e
                if attempt < self.max_retries:
                    wait_time = 2 ** attempt  # Exponential backoff
                    self.logger.warning(f"⚠️ Retry {attempt + 1}/{self.max_retries} for message {message.id} in {wait_time}s")
                    await asyncio.sleep(wait_time)
                else:
                    self.logger.error(f"❌ All retries exhausted for message {message.id}")
        
        raise last_exception

    async def _health_monitoring_loop(self):
        """Monitor agent health and update metrics"""
        while self.is_running:
            try:
                # Perform health check
                health_status = await self.health_check()
                self.is_healthy = health_status.get("healthy", False)
                
                # Update uptime
                if self.start_time:
                    self.metrics.uptime = (datetime.utcnow() - self.start_time).total_seconds()
                
                # Calculate error rate
                total_messages = self.metrics.messages_processed + self.metrics.messages_failed
                if total_messages > 0:
                    self.metrics.error_rate = self.metrics.messages_failed / total_messages
                
                # Log health status
                await self._log_agent_activity("health_check", {
                    "healthy": self.is_healthy,
                    "uptime": self.metrics.uptime,
                    "error_rate": self.metrics.error_rate,
                    "messages_processed": self.metrics.messages_processed
                })
                
                # Wait before next health check
                await asyncio.sleep(settings.AGENT_HEARTBEAT_INTERVAL)
                
            except Exception as e:
                self.logger.error(f"❌ Error in health monitoring: {e}")
                self.is_healthy = False
                await asyncio.sleep(10)

    async def _startup_initialization(self):
        """Perform agent-specific startup initialization"""
        try:
            await self._initialize_resources()
            self.logger.info(f"✅ Agent {self.agent_name} startup complete")
        except Exception as e:
            self.logger.error(f"❌ Agent {self.agent_name} startup failed: {e}")
            self.is_healthy = False

    async def _initialize_resources(self):
        """Initialize agent-specific resources (override in subclasses)"""
        pass

    async def _cleanup(self):
        """Cleanup agent resources (override in subclasses)"""
        pass

    async def _send_response(self, response: AgentMessage):
        """Send response message"""
        # Implementation would depend on messaging system
        self.logger.debug(f"📤 Sending response to {response.recipient}")

    async def _log_agent_activity(self, activity_type: str, metadata: Dict[str, Any]):
        """Log agent activity for UEBA monitoring"""
        log_entry = {
            "agent_name": self.agent_name,
            "activity_type": activity_type,
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": metadata
        }
        
        # This would be sent to the UEBA agent for behavior analysis
        self.logger.debug(f"📊 Activity logged: {activity_type}")

    def get_status(self) -> Dict[str, Any]:
        """Get current agent status"""
        return {
            "agent_name": self.agent_name,
            "version": self.version,
            "is_running": self.is_running,
            "is_healthy": self.is_healthy,
            "capabilities": self.capabilities,
            "uptime": self.metrics.uptime,
            "messages_processed": self.metrics.messages_processed,
            "messages_failed": self.metrics.messages_failed,
            "error_rate": self.metrics.error_rate,
            "average_processing_time": self.metrics.average_processing_time,
            "last_activity": self.metrics.last_activity.isoformat() if self.metrics.last_activity else None
        }

    def __repr__(self):
        return f"<{self.__class__.__name__}(name={self.agent_name}, running={self.is_running}, healthy={self.is_healthy})>"