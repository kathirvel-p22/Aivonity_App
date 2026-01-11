"""
AIVONITY WebSocket Manager
Advanced WebSocket connection management with real-time capabilities
"""

import asyncio
import json
import logging
from typing import Dict, List, Set, Optional, Any
from datetime import datetime
from dataclasses import dataclass, field
from fastapi import WebSocket, WebSocketDisconnect
import uuid

from app.config import settings
from app.utils.logging_config import get_logger

logger = get_logger(__name__)

@dataclass
class WebSocketConnection:
    """WebSocket connection metadata"""
    websocket: WebSocket
    connection_id: str
    user_id: Optional[str] = None
    vehicle_id: Optional[str] = None
    groups: Set[str] = field(default_factory=set)
    connected_at: datetime = field(default_factory=datetime.utcnow)
    last_activity: datetime = field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class WebSocketMessage:
    """Standardized WebSocket message format"""
    message_type: str
    data: Dict[str, Any]
    timestamp: datetime = field(default_factory=datetime.utcnow)
    message_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    sender: Optional[str] = None
    recipient: Optional[str] = None

class WebSocketManager:
    """
    Advanced WebSocket connection manager with group support,
    message broadcasting, and connection health monitoring
    """
    
    def __init__(self):
        # Connection storage
        self.connections: Dict[str, WebSocketConnection] = {}
        self.groups: Dict[str, Set[str]] = {}  # group_name -> set of connection_ids
        self.user_connections: Dict[str, Set[str]] = {}  # user_id -> set of connection_ids
        
        # Configuration
        self.max_connections = settings.MAX_WEBSOCKET_CONNECTIONS
        self.heartbeat_interval = settings.WEBSOCKET_HEARTBEAT_INTERVAL
        
        # Statistics
        self.total_connections = 0
        self.total_messages_sent = 0
        self.total_messages_received = 0
        
        # Start background tasks
        asyncio.create_task(self._heartbeat_loop())
        asyncio.create_task(self._cleanup_loop())
        
        logger.info("🔌 WebSocket Manager initialized")

    async def connect(self, websocket: WebSocket, group: str = None, 
                     user_id: str = None, vehicle_id: str = None) -> str:
        """
        Accept WebSocket connection and add to management
        
        Args:
            websocket: WebSocket instance
            group: Optional group to join
            user_id: Optional user ID for user-specific messaging
            vehicle_id: Optional vehicle ID for vehicle-specific messaging
            
        Returns:
            Connection ID
        """
        try:
            # Check connection limit
            if len(self.connections) >= self.max_connections:
                await websocket.close(code=1013, reason="Server overloaded")
                logger.warning("⚠️ WebSocket connection rejected: max connections reached")
                return None
            
            # Accept connection
            await websocket.accept()
            
            # Create connection metadata
            connection_id = str(uuid.uuid4())
            connection = WebSocketConnection(
                websocket=websocket,
                connection_id=connection_id,
                user_id=user_id,
                vehicle_id=vehicle_id
            )
            
            # Store connection
            self.connections[connection_id] = connection
            
            # Add to user connections if user_id provided
            if user_id:
                if user_id not in self.user_connections:
                    self.user_connections[user_id] = set()
                self.user_connections[user_id].add(connection_id)
            
            # Join group if specified
            if group:
                await self.join_group(connection_id, group)
            
            # Update statistics
            self.total_connections += 1
            
            # Send welcome message
            await self.send_to_connection(connection_id, WebSocketMessage(
                message_type="connection_established",
                data={
                    "connection_id": connection_id,
                    "timestamp": datetime.utcnow().isoformat(),
                    "server_info": {
                        "service": "AIVONITY",
                        "version": "1.0.0"
                    }
                }
            ))
            
            logger.info(f"✅ WebSocket connected: {connection_id} (user: {user_id}, group: {group})")
            return connection_id
            
        except Exception as e:
            logger.error(f"❌ Error connecting WebSocket: {e}")
            return None

    def disconnect(self, websocket: WebSocket, group: str = None):
        """
        Disconnect WebSocket and cleanup
        
        Args:
            websocket: WebSocket instance to disconnect
            group: Optional group name for group-based disconnection
        """
        try:
            # Find connection by websocket instance
            connection_id = None
            for conn_id, conn in self.connections.items():
                if conn.websocket == websocket:
                    connection_id = conn_id
                    break
            
            if connection_id:
                self._cleanup_connection(connection_id)
                logger.info(f"🔌 WebSocket disconnected: {connection_id}")
            else:
                logger.warning("⚠️ Attempted to disconnect unknown WebSocket")
                
        except Exception as e:
            logger.error(f"❌ Error disconnecting WebSocket: {e}")

    async def send_to_connection(self, connection_id: str, message: WebSocketMessage):
        """
        Send message to specific connection
        
        Args:
            connection_id: Target connection ID
            message: Message to send
        """
        try:
            if connection_id not in self.connections:
                logger.warning(f"⚠️ Connection not found: {connection_id}")
                return False
            
            connection = self.connections[connection_id]
            
            # Prepare message
            message_data = {
                "type": message.message_type,
                "data": message.data,
                "timestamp": message.timestamp.isoformat(),
                "message_id": message.message_id
            }
            
            # Send message
            await connection.websocket.send_text(json.dumps(message_data))
            
            # Update activity
            connection.last_activity = datetime.utcnow()
            self.total_messages_sent += 1
            
            logger.debug(f"📤 Message sent to {connection_id}: {message.message_type}")
            return True
            
        except WebSocketDisconnect:
            logger.info(f"🔌 Connection {connection_id} disconnected during send")
            self._cleanup_connection(connection_id)
            return False
        except Exception as e:
            logger.error(f"❌ Error sending message to {connection_id}: {e}")
            return False

    async def send_to_user(self, user_id: str, message: WebSocketMessage):
        """
        Send message to all connections of a specific user
        
        Args:
            user_id: Target user ID
            message: Message to send
        """
        try:
            if user_id not in self.user_connections:
                logger.debug(f"📭 No connections found for user: {user_id}")
                return 0
            
            sent_count = 0
            connection_ids = list(self.user_connections[user_id])  # Copy to avoid modification during iteration
            
            for connection_id in connection_ids:
                if await self.send_to_connection(connection_id, message):
                    sent_count += 1
            
            logger.debug(f"📤 Message sent to {sent_count} connections for user {user_id}")
            return sent_count
            
        except Exception as e:
            logger.error(f"❌ Error sending message to user {user_id}: {e}")
            return 0

    async def broadcast_to_group(self, group: str, message: WebSocketMessage, 
                               exclude_connection: str = None):
        """
        Broadcast message to all connections in a group
        
        Args:
            group: Target group name
            message: Message to broadcast
            exclude_connection: Optional connection ID to exclude
        """
        try:
            if group not in self.groups:
                logger.debug(f"📭 Group not found: {group}")
                return 0
            
            sent_count = 0
            connection_ids = list(self.groups[group])  # Copy to avoid modification during iteration
            
            for connection_id in connection_ids:
                if connection_id != exclude_connection:
                    if await self.send_to_connection(connection_id, message):
                        sent_count += 1
            
            logger.debug(f"📡 Broadcast to group {group}: {sent_count} connections")
            return sent_count
            
        except Exception as e:
            logger.error(f"❌ Error broadcasting to group {group}: {e}")
            return 0

    async def broadcast_to_all(self, message: WebSocketMessage, 
                             exclude_connection: str = None):
        """
        Broadcast message to all active connections
        
        Args:
            message: Message to broadcast
            exclude_connection: Optional connection ID to exclude
        """
        try:
            sent_count = 0
            connection_ids = list(self.connections.keys())  # Copy to avoid modification during iteration
            
            for connection_id in connection_ids:
                if connection_id != exclude_connection:
                    if await self.send_to_connection(connection_id, message):
                        sent_count += 1
            
            logger.info(f"📡 Global broadcast: {sent_count} connections")
            return sent_count
            
        except Exception as e:
            logger.error(f"❌ Error broadcasting to all connections: {e}")
            return 0

    async def join_group(self, connection_id: str, group: str):
        """
        Add connection to a group
        
        Args:
            connection_id: Connection ID to add
            group: Group name to join
        """
        try:
            if connection_id not in self.connections:
                logger.warning(f"⚠️ Cannot join group: connection {connection_id} not found")
                return False
            
            # Add to group
            if group not in self.groups:
                self.groups[group] = set()
            self.groups[group].add(connection_id)
            
            # Update connection metadata
            self.connections[connection_id].groups.add(group)
            
            logger.debug(f"👥 Connection {connection_id} joined group {group}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error joining group {group}: {e}")
            return False

    async def leave_group(self, connection_id: str, group: str):
        """
        Remove connection from a group
        
        Args:
            connection_id: Connection ID to remove
            group: Group name to leave
        """
        try:
            if group in self.groups and connection_id in self.groups[group]:
                self.groups[group].remove(connection_id)
                
                # Clean up empty group
                if not self.groups[group]:
                    del self.groups[group]
            
            # Update connection metadata
            if connection_id in self.connections:
                self.connections[connection_id].groups.discard(group)
            
            logger.debug(f"👥 Connection {connection_id} left group {group}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error leaving group {group}: {e}")
            return False

    async def get_connection_info(self, connection_id: str) -> Optional[Dict[str, Any]]:
        """
        Get connection information
        
        Args:
            connection_id: Connection ID
            
        Returns:
            Connection information dictionary
        """
        try:
            if connection_id not in self.connections:
                return None
            
            connection = self.connections[connection_id]
            return {
                "connection_id": connection.connection_id,
                "user_id": connection.user_id,
                "vehicle_id": connection.vehicle_id,
                "groups": list(connection.groups),
                "connected_at": connection.connected_at.isoformat(),
                "last_activity": connection.last_activity.isoformat(),
                "metadata": connection.metadata
            }
            
        except Exception as e:
            logger.error(f"❌ Error getting connection info: {e}")
            return None

    def get_statistics(self) -> Dict[str, Any]:
        """Get WebSocket manager statistics"""
        return {
            "active_connections": len(self.connections),
            "total_connections": self.total_connections,
            "active_groups": len(self.groups),
            "messages_sent": self.total_messages_sent,
            "messages_received": self.total_messages_received,
            "users_connected": len(self.user_connections),
            "group_details": {
                group: len(connections) 
                for group, connections in self.groups.items()
            }
        }

    def _cleanup_connection(self, connection_id: str):
        """
        Clean up connection and associated data
        
        Args:
            connection_id: Connection ID to clean up
        """
        try:
            if connection_id not in self.connections:
                return
            
            connection = self.connections[connection_id]
            
            # Remove from user connections
            if connection.user_id and connection.user_id in self.user_connections:
                self.user_connections[connection.user_id].discard(connection_id)
                if not self.user_connections[connection.user_id]:
                    del self.user_connections[connection.user_id]
            
            # Remove from all groups
            for group in list(connection.groups):
                if group in self.groups:
                    self.groups[group].discard(connection_id)
                    if not self.groups[group]:
                        del self.groups[group]
            
            # Remove connection
            del self.connections[connection_id]
            
            logger.debug(f"🧹 Connection {connection_id} cleaned up")
            
        except Exception as e:
            logger.error(f"❌ Error cleaning up connection {connection_id}: {e}")

    async def _heartbeat_loop(self):
        """Background task to send heartbeat messages"""
        while True:
            try:
                await asyncio.sleep(self.heartbeat_interval)
                
                # Send heartbeat to all connections
                heartbeat_message = WebSocketMessage(
                    message_type="heartbeat",
                    data={
                        "timestamp": datetime.utcnow().isoformat(),
                        "server_status": "healthy"
                    }
                )
                
                # Send heartbeat to all active connections
                failed_connections = []
                for connection_id in list(self.connections.keys()):
                    try:
                        if not await self.send_to_connection(connection_id, heartbeat_message):
                            failed_connections.append(connection_id)
                    except Exception:
                        failed_connections.append(connection_id)
                
                # Clean up failed connections
                for connection_id in failed_connections:
                    self._cleanup_connection(connection_id)
                
                if failed_connections:
                    logger.info(f"💓 Heartbeat: cleaned up {len(failed_connections)} stale connections")
                
            except Exception as e:
                logger.error(f"❌ Error in heartbeat loop: {e}")
                await asyncio.sleep(5)

    async def _cleanup_loop(self):
        """Background task to clean up inactive connections"""
        while True:
            try:
                await asyncio.sleep(300)  # Run every 5 minutes
                
                current_time = datetime.utcnow()
                inactive_connections = []
                
                # Find inactive connections (no activity for 30 minutes)
                for connection_id, connection in self.connections.items():
                    if (current_time - connection.last_activity).total_seconds() > 1800:  # 30 minutes
                        inactive_connections.append(connection_id)
                
                # Clean up inactive connections
                for connection_id in inactive_connections:
                    try:
                        connection = self.connections[connection_id]
                        await connection.websocket.close(code=1000, reason="Inactive connection")
                        self._cleanup_connection(connection_id)
                    except Exception:
                        self._cleanup_connection(connection_id)
                
                if inactive_connections:
                    logger.info(f"🧹 Cleaned up {len(inactive_connections)} inactive connections")
                
            except Exception as e:
                logger.error(f"❌ Error in cleanup loop: {e}")
                await asyncio.sleep(60)