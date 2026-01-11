"""
AIVONITY Agent Manager
Advanced orchestration and management of AI agents
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime
import json
import redis.asyncio as redis
from dataclasses import asdict

from app.agents.base_agent import BaseAgent, AgentMessage
from app.agents.data_agent import DataAgent
from app.config import settings
from app.utils.logging_config import get_logger

logger = get_logger(__name__)

class AgentManager:
    """
    Advanced Agent Manager for orchestrating AI agents
    Handles agent lifecycle, communication, and health monitoring
    """
    
    def __init__(self):
        self.agents: Dict[str, BaseAgent] = {}
        self.agent_configs = self._load_agent_configurations()
        
        # Redis for inter-agent communication
        self.redis_client = None
        self.message_handlers = {}
        
        # Agent registry and status
        self.agent_registry = {}
        self.agent_health_status = {}
        
        # Performance metrics
        self.total_messages_processed = 0
        self.agent_performance_metrics = {}
        
        logger.info("🤖 Agent Manager initialized")

    async def initialize_redis(self):
        """Initialize Redis connection for agent communication"""
        try:
            self.redis_client = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            
            # Test connection
            await self.redis_client.ping()
            logger.info("✅ Redis connection established for agent communication")
            
            # Start message listener
            asyncio.create_task(self._message_listener())
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize Redis: {e}")
            raise

    def _load_agent_configurations(self) -> Dict[str, Dict[str, Any]]:
        """Load agent configurations"""
        return {
            "data_agent": {
                "enabled": True,
                "batch_size": 100,
                "processing_interval": 5,
                "anomaly_threshold": 0.7,
                "max_retries": 3,
                "timeout": 30
            },
            "diagnosis_agent": {
                "enabled": True,
                "model_update_interval": 3600,
                "prediction_threshold": 0.8,
                "max_retries": 3,
                "timeout": 45
            },
            "scheduling_agent": {
                "enabled": True,
                "optimization_timeout": 60,
                "max_alternatives": 5,
                "max_retries": 3,
                "timeout": 30
            },
            "customer_agent": {
                "enabled": True,
                "ai_model": "gpt-4",
                "max_context_length": 4000,
                "response_timeout": 10,
                "max_retries": 2,
                "timeout": 15
            },
            "feedback_agent": {
                "enabled": True,
                "analysis_batch_size": 50,
                "report_generation_interval": 86400,  # 24 hours
                "max_retries": 3,
                "timeout": 60
            },
            "ueba_agent": {
                "enabled": True,
                "monitoring_interval": 300,  # 5 minutes
                "anomaly_threshold": 0.8,
                "alert_threshold": 0.9,
                "max_retries": 3,
                "timeout": 20
            }
        }

    async def start_all_agents(self):
        """Start all configured agents"""
        try:
            # Initialize Redis first
            await self.initialize_redis()
            
            # Start each enabled agent
            for agent_name, config in self.agent_configs.items():
                if config.get("enabled", False):
                    await self.start_agent(agent_name, config)
            
            logger.info(f"✅ Started {len(self.agents)} agents successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to start agents: {e}")
            raise

    async def start_agent(self, agent_name: str, config: Dict[str, Any]):
        """Start individual agent"""
        try:
            # Create agent instance based on type
            agent = self._create_agent_instance(agent_name, config)
            
            if agent:
                # Start the agent
                await agent.start()
                
                # Register agent
                self.agents[agent_name] = agent
                self.agent_registry[agent_name] = {
                    "status": "running",
                    "started_at": datetime.utcnow().isoformat(),
                    "config": config,
                    "capabilities": agent.capabilities
                }
                
                # Initialize performance metrics
                self.agent_performance_metrics[agent_name] = {
                    "messages_processed": 0,
                    "messages_failed": 0,
                    "average_response_time": 0.0,
                    "last_activity": None
                }
                
                logger.info(f"✅ Agent {agent_name} started successfully")
            else:
                logger.error(f"❌ Failed to create agent instance: {agent_name}")
                
        except Exception as e:
            logger.error(f"❌ Failed to start agent {agent_name}: {e}")
            raise

    def _create_agent_instance(self, agent_name: str, config: Dict[str, Any]) -> Optional[BaseAgent]:
        """Create agent instance based on agent type"""
        try:
            if agent_name == "data_agent":
                return DataAgent(config)
            
            elif agent_name == "diagnosis_agent":
                # Import and create DiagnosisAgent when implemented
                logger.info(f"📋 {agent_name} will be implemented in next phase")
                return None
            
            elif agent_name == "scheduling_agent":
                # Import and create SchedulingAgent when implemented
                logger.info(f"📋 {agent_name} will be implemented in next phase")
                return None
            
            elif agent_name == "customer_agent":
                # Import and create CustomerAgent when implemented
                logger.info(f"📋 {agent_name} will be implemented in next phase")
                return None
            
            elif agent_name == "feedback_agent":
                # Import and create FeedbackAgent when implemented
                logger.info(f"📋 {agent_name} will be implemented in next phase")
                return None
            
            elif agent_name == "ueba_agent":
                from app.agents.ueba_agent import UEBAAgent
                return UEBAAgent(config)
            
            else:
                logger.error(f"❌ Unknown agent type: {agent_name}")
                return None
                
        except Exception as e:
            logger.error(f"❌ Error creating agent {agent_name}: {e}")
            return None

    async def stop_all_agents(self):
        """Stop all running agents"""
        try:
            for agent_name, agent in self.agents.items():
                await self.stop_agent(agent_name)
            
            # Close Redis connection
            if self.redis_client:
                await self.redis_client.close()
            
            logger.info("🛑 All agents stopped successfully")
            
        except Exception as e:
            logger.error(f"❌ Error stopping agents: {e}")

    async def stop_agent(self, agent_name: str):
        """Stop individual agent"""
        try:
            if agent_name in self.agents:
                agent = self.agents[agent_name]
                await agent.stop()
                
                # Update registry
                if agent_name in self.agent_registry:
                    self.agent_registry[agent_name]["status"] = "stopped"
                    self.agent_registry[agent_name]["stopped_at"] = datetime.utcnow().isoformat()
                
                # Remove from active agents
                del self.agents[agent_name]
                
                logger.info(f"🛑 Agent {agent_name} stopped successfully")
            else:
                logger.warning(f"⚠️ Agent {agent_name} not found in active agents")
                
        except Exception as e:
            logger.error(f"❌ Error stopping agent {agent_name}: {e}")

    async def send_message_to_agent(self, recipient: str, message_type: str, 
                                  payload: Dict[str, Any], sender: str = "agent_manager",
                                  priority: int = 1, correlation_id: str = None) -> str:
        """Send message to specific agent"""
        try:
            message = AgentMessage(
                sender=sender,
                recipient=recipient,
                message_type=message_type,
                payload=payload,
                priority=priority,
                correlation_id=correlation_id
            )
            
            # Send via Redis pub/sub
            channel = f"agent:{recipient}"
            message_data = message.to_dict()
            
            await self.redis_client.publish(channel, json.dumps(message_data))
            
            logger.debug(f"📤 Message sent to {recipient}: {message_type}")
            return message.id
            
        except Exception as e:
            logger.error(f"❌ Error sending message to {recipient}: {e}")
            return None

    async def broadcast_message(self, message_type: str, payload: Dict[str, Any], 
                              sender: str = "agent_manager", exclude_agents: List[str] = None):
        """Broadcast message to all agents"""
        try:
            exclude_agents = exclude_agents or []
            sent_count = 0
            
            for agent_name in self.agents.keys():
                if agent_name not in exclude_agents:
                    message_id = await self.send_message_to_agent(
                        recipient=agent_name,
                        message_type=message_type,
                        payload=payload,
                        sender=sender
                    )
                    if message_id:
                        sent_count += 1
            
            logger.info(f"📡 Broadcast message sent to {sent_count} agents")
            return sent_count
            
        except Exception as e:
            logger.error(f"❌ Error broadcasting message: {e}")
            return 0

    async def _message_listener(self):
        """Listen for agent messages via Redis pub/sub"""
        try:
            pubsub = self.redis_client.pubsub()
            
            # Subscribe to agent manager channel
            await pubsub.subscribe("agent:manager")
            
            logger.info("👂 Agent message listener started")
            
            async for message in pubsub.listen():
                if message["type"] == "message":
                    try:
                        message_data = json.loads(message["data"])
                        agent_message = AgentMessage(**message_data)
                        
                        # Process the message
                        await self._handle_agent_message(agent_message)
                        
                    except Exception as e:
                        logger.error(f"❌ Error processing agent message: {e}")
                        
        except Exception as e:
            logger.error(f"❌ Error in message listener: {e}")

    async def _handle_agent_message(self, message: AgentMessage):
        """Handle incoming agent messages"""
        try:
            message_type = message.message_type
            sender = message.sender
            payload = message.payload
            
            # Update performance metrics
            if sender in self.agent_performance_metrics:
                self.agent_performance_metrics[sender]["messages_processed"] += 1
                self.agent_performance_metrics[sender]["last_activity"] = datetime.utcnow().isoformat()
            
            # Handle different message types
            if message_type == "health_status":
                await self._handle_health_status(sender, payload)
            
            elif message_type == "performance_metrics":
                await self._handle_performance_metrics(sender, payload)
            
            elif message_type == "error_report":
                await self._handle_error_report(sender, payload)
            
            elif message_type == "agent_request":
                await self._handle_agent_request(message)
            
            else:
                logger.debug(f"📥 Received message from {sender}: {message_type}")
            
            self.total_messages_processed += 1
            
        except Exception as e:
            logger.error(f"❌ Error handling agent message: {e}")

    async def _handle_health_status(self, agent_name: str, payload: Dict[str, Any]):
        """Handle agent health status updates"""
        try:
            self.agent_health_status[agent_name] = {
                "status": payload.get("status", "unknown"),
                "timestamp": payload.get("timestamp", datetime.utcnow().isoformat()),
                "metrics": payload.get("metrics", {}),
                "issues": payload.get("issues", [])
            }
            
            # Check for critical issues
            if payload.get("status") == "critical":
                logger.warning(f"⚠️ Critical health status from {agent_name}: {payload.get('issues', [])}")
                
                # Potentially restart agent or take corrective action
                await self._handle_critical_agent_status(agent_name, payload)
            
        except Exception as e:
            logger.error(f"❌ Error handling health status from {agent_name}: {e}")

    async def _handle_performance_metrics(self, agent_name: str, payload: Dict[str, Any]):
        """Handle agent performance metrics"""
        try:
            if agent_name in self.agent_performance_metrics:
                metrics = self.agent_performance_metrics[agent_name]
                
                # Update metrics
                metrics.update(payload)
                
                # Check for performance issues
                avg_response_time = payload.get("average_response_time", 0)
                error_rate = payload.get("error_rate", 0)
                
                if avg_response_time > 10.0:  # 10 seconds
                    logger.warning(f"⚠️ High response time for {agent_name}: {avg_response_time}s")
                
                if error_rate > 0.1:  # 10% error rate
                    logger.warning(f"⚠️ High error rate for {agent_name}: {error_rate * 100}%")
            
        except Exception as e:
            logger.error(f"❌ Error handling performance metrics from {agent_name}: {e}")

    async def _handle_error_report(self, agent_name: str, payload: Dict[str, Any]):
        """Handle agent error reports"""
        try:
            error_type = payload.get("error_type", "unknown")
            error_message = payload.get("error_message", "")
            severity = payload.get("severity", "medium")
            
            logger.error(f"❌ Error report from {agent_name} ({severity}): {error_type} - {error_message}")
            
            # Update failure metrics
            if agent_name in self.agent_performance_metrics:
                self.agent_performance_metrics[agent_name]["messages_failed"] += 1
            
            # Handle critical errors
            if severity == "critical":
                await self._handle_critical_agent_error(agent_name, payload)
            
        except Exception as e:
            logger.error(f"❌ Error handling error report from {agent_name}: {e}")

    async def _handle_agent_request(self, message: AgentMessage):
        """Handle requests from agents"""
        try:
            request_type = message.payload.get("request_type")
            
            if request_type == "restart_agent":
                target_agent = message.payload.get("target_agent")
                if target_agent and target_agent in self.agents:
                    logger.info(f"🔄 Restarting agent {target_agent} as requested by {message.sender}")
                    await self.restart_agent(target_agent)
            
            elif request_type == "get_agent_status":
                # Send agent status back to requester
                status = self.get_agents_status()
                await self.send_message_to_agent(
                    recipient=message.sender,
                    message_type="agent_status_response",
                    payload={"status": status},
                    correlation_id=message.correlation_id
                )
            
        except Exception as e:
            logger.error(f"❌ Error handling agent request: {e}")

    async def _handle_critical_agent_status(self, agent_name: str, payload: Dict[str, Any]):
        """Handle critical agent status"""
        try:
            logger.warning(f"🚨 Critical status from {agent_name}, attempting recovery")
            
            # Try to restart the agent
            await self.restart_agent(agent_name)
            
        except Exception as e:
            logger.error(f"❌ Error handling critical agent status: {e}")

    async def _handle_critical_agent_error(self, agent_name: str, payload: Dict[str, Any]):
        """Handle critical agent errors"""
        try:
            logger.error(f"🚨 Critical error from {agent_name}, initiating recovery")
            
            # Try to restart the agent
            await self.restart_agent(agent_name)
            
        except Exception as e:
            logger.error(f"❌ Error handling critical agent error: {e}")

    async def restart_agent(self, agent_name: str):
        """Restart specific agent"""
        try:
            logger.info(f"🔄 Restarting agent {agent_name}")
            
            # Stop the agent
            await self.stop_agent(agent_name)
            
            # Wait a moment
            await asyncio.sleep(2)
            
            # Start the agent again
            if agent_name in self.agent_configs:
                config = self.agent_configs[agent_name]
                await self.start_agent(agent_name, config)
                logger.info(f"✅ Agent {agent_name} restarted successfully")
            else:
                logger.error(f"❌ No configuration found for agent {agent_name}")
                
        except Exception as e:
            logger.error(f"❌ Error restarting agent {agent_name}: {e}")

    async def health_check_all(self) -> Dict[str, Any]:
        """Perform health check on all agents"""
        try:
            health_results = {}
            
            for agent_name, agent in self.agents.items():
                try:
                    health_status = await agent.health_check()
                    health_results[agent_name] = health_status
                except Exception as e:
                    health_results[agent_name] = {
                        "healthy": False,
                        "error": str(e),
                        "timestamp": datetime.utcnow().isoformat()
                    }
            
            return health_results
            
        except Exception as e:
            logger.error(f"❌ Error in health check: {e}")
            return {"error": str(e)}

    def get_agents_status(self) -> Dict[str, Any]:
        """Get status of all agents"""
        try:
            status = {
                "total_agents": len(self.agent_configs),
                "running_agents": len(self.agents),
                "agent_details": {},
                "performance_summary": {
                    "total_messages_processed": self.total_messages_processed,
                    "agent_performance": self.agent_performance_metrics
                },
                "health_status": self.agent_health_status,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Add individual agent status
            for agent_name, agent in self.agents.items():
                status["agent_details"][agent_name] = agent.get_status()
            
            return status
            
        except Exception as e:
            logger.error(f"❌ Error getting agents status: {e}")
            return {"error": str(e)}

    async def process_chat_message(self, user_id: str, message: Dict[str, Any]) -> Dict[str, Any]:
        """Process chat message through Customer Agent"""
        try:
            # For now, return a simple response since Customer Agent is not implemented yet
            response = {
                "message_id": message.get("message_id", ""),
                "response": "Hello! I'm AIVONITY, your intelligent vehicle assistant. The full conversational AI is being implemented. How can I help you with your vehicle today?",
                "timestamp": datetime.utcnow().isoformat(),
                "agent": "aivonity_assistant",
                "user_id": user_id
            }
            
            logger.info(f"💬 Processed chat message for user {user_id}")
            return response
            
        except Exception as e:
            logger.error(f"❌ Error processing chat message: {e}")
            return {
                "error": "Sorry, I'm experiencing technical difficulties. Please try again later.",
                "timestamp": datetime.utcnow().isoformat()
            }