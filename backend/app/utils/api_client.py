"""
AIVONITY API Client with Retry Logic and Circuit Breaker
Resilient API client for external service integration
"""

import asyncio
import aiohttp
import json
from typing import Any, Dict, Optional, Union, List
from dataclasses import dataclass
from enum import Enum
import logging
from urllib.parse import urljoin

from app.utils.retry_handler import RetryHandler, RetryConfigs
from app.utils.circuit_breaker import CircuitBreaker, CircuitBreakerConfigs
from app.utils.exceptions import (
    ExternalServiceError,
    NetworkError,
    RateLimitError,
    AuthenticationError,
    ValidationError
)


class HTTPMethod(str, Enum):
    """HTTP methods"""
    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    PATCH = "PATCH"
    DELETE = "DELETE"


@dataclass
class APIResponse:
    """Standardized API response"""
    status_code: int
    data: Any
    headers: Dict[str, str]
    success: bool
    error_message: Optional[str] = None


class ResilientAPIClient:
    """Resilient API client with retry logic and circuit breaker"""
    
    def __init__(
        self,
        base_url: str,
        service_name: str,
        timeout: int = 30,
        retry_handler: Optional[RetryHandler] = None,
        circuit_breaker: Optional[CircuitBreaker] = None,
        default_headers: Optional[Dict[str, str]] = None
    ):
        self.base_url = base_url.rstrip('/')
        self.service_name = service_name
        self.timeout = aiohttp.ClientTimeout(total=timeout)
        self.retry_handler = retry_handler or RetryHandler(RetryConfigs.EXTERNAL_SERVICE)
        self.circuit_breaker = circuit_breaker or CircuitBreaker(
            name=f"api_client_{service_name}",
            config=CircuitBreakerConfigs.EXTERNAL_API
        )
        self.default_headers = default_headers or {}
        self.logger = logging.getLogger(f"api_client.{service_name}")
        
        # Session will be created when needed
        self._session: Optional[aiohttp.ClientSession] = None
    
    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session"""
        if self._session is None or self._session.closed:
            connector = aiohttp.TCPConnector(
                limit=100,  # Total connection pool size
                limit_per_host=30,  # Per-host connection limit
                ttl_dns_cache=300,  # DNS cache TTL
                use_dns_cache=True,
                keepalive_timeout=30,
                enable_cleanup_closed=True
            )
            
            self._session = aiohttp.ClientSession(
                connector=connector,
                timeout=self.timeout,
                headers=self.default_headers,
                raise_for_status=False  # We'll handle status codes manually
            )
        
        return self._session
    
    async def close(self):
        """Close the HTTP session"""
        if self._session and not self._session.closed:
            await self._session.close()
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()
    
    def _build_url(self, endpoint: str) -> str:
        """Build full URL from endpoint"""
        return urljoin(self.base_url + '/', endpoint.lstrip('/'))
    
    def _prepare_headers(self, headers: Optional[Dict[str, str]] = None) -> Dict[str, str]:
        """Prepare request headers"""
        request_headers = self.default_headers.copy()
        if headers:
            request_headers.update(headers)
        return request_headers
    
    def _handle_response_status(self, response: aiohttp.ClientResponse, data: Any) -> APIResponse:
        """Handle response status and create appropriate exceptions"""
        
        if response.status == 200 or response.status == 201:
            return APIResponse(
                status_code=response.status,
                data=data,
                headers=dict(response.headers),
                success=True
            )
        
        # Handle specific error status codes
        error_message = self._extract_error_message(data)
        
        if response.status == 401:
            raise AuthenticationError(
                message=error_message or "Authentication failed",
                details={'status_code': response.status, 'service': self.service_name}
            )
        elif response.status == 422:
            raise ValidationError(
                message=error_message or "Validation failed",
                details={'status_code': response.status, 'service': self.service_name}
            )
        elif response.status == 429:
            retry_after = response.headers.get('Retry-After')
            raise RateLimitError(
                limit=0,  # Unknown limit
                window=60,  # Default window
                retry_after=int(retry_after) if retry_after else 60,
                details={'status_code': response.status, 'service': self.service_name}
            )
        elif response.status >= 500:
            raise ExternalServiceError(
                service_name=self.service_name,
                message=error_message or f"Server error: {response.status}",
                details={'status_code': response.status}
            )
        else:
            raise ExternalServiceError(
                service_name=self.service_name,
                message=error_message or f"HTTP error: {response.status}",
                details={'status_code': response.status}
            )
    
    def _extract_error_message(self, data: Any) -> Optional[str]:
        """Extract error message from response data"""
        if isinstance(data, dict):
            # Try common error message fields
            for field in ['error', 'message', 'detail', 'error_description']:
                if field in data:
                    error_data = data[field]
                    if isinstance(error_data, str):
                        return error_data
                    elif isinstance(error_data, dict) and 'message' in error_data:
                        return error_data['message']
        return None
    
    async def _make_request(
        self,
        method: HTTPMethod,
        endpoint: str,
        data: Optional[Union[Dict, List]] = None,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make HTTP request with error handling"""
        
        session = await self._get_session()
        url = self._build_url(endpoint)
        request_headers = self._prepare_headers(headers)
        
        # Prepare request data
        json_data = None
        if data is not None:
            json_data = data
            request_headers['Content-Type'] = 'application/json'
        
        self.logger.debug(
            f"Making {method.value} request to {url}",
            extra={
                'method': method.value,
                'url': url,
                'service': self.service_name,
                'has_data': data is not None
            }
        )
        
        try:
            async with session.request(
                method.value,
                url,
                json=json_data,
                params=params,
                headers=request_headers,
                **kwargs
            ) as response:
                
                # Try to parse JSON response
                try:
                    response_data = await response.json()
                except (aiohttp.ContentTypeError, json.JSONDecodeError):
                    # Fallback to text if JSON parsing fails
                    response_data = await response.text()
                
                # Handle response status
                api_response = self._handle_response_status(response, response_data)
                
                self.logger.debug(
                    f"Request completed: {method.value} {url} -> {response.status}",
                    extra={
                        'method': method.value,
                        'url': url,
                        'status_code': response.status,
                        'service': self.service_name
                    }
                )
                
                return api_response
                
        except aiohttp.ClientError as e:
            self.logger.error(
                f"Client error for {method.value} {url}: {str(e)}",
                extra={
                    'method': method.value,
                    'url': url,
                    'service': self.service_name,
                    'error': str(e)
                }
            )
            raise NetworkError(
                message=f"Network error: {str(e)}",
                details={'service': self.service_name, 'url': url}
            )
        except asyncio.TimeoutError:
            self.logger.error(
                f"Timeout for {method.value} {url}",
                extra={
                    'method': method.value,
                    'url': url,
                    'service': self.service_name,
                    'timeout': self.timeout.total
                }
            )
            raise NetworkError(
                message=f"Request timeout after {self.timeout.total}s",
                details={'service': self.service_name, 'url': url}
            )
    
    async def get(
        self,
        endpoint: str,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make GET request with resilience"""
        async def _request():
            return await self._make_request(
                HTTPMethod.GET, endpoint, params=params, headers=headers, **kwargs
            )
        
        return await self.circuit_breaker.call_async(
            lambda: self.retry_handler.execute_async(
                _request,
                context={'service': self.service_name, 'endpoint': endpoint}
            )
        )
    
    async def post(
        self,
        endpoint: str,
        data: Optional[Union[Dict, List]] = None,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make POST request with resilience"""
        async def _request():
            return await self._make_request(
                HTTPMethod.POST, endpoint, data=data, params=params, headers=headers, **kwargs
            )
        
        return await self.circuit_breaker.call_async(
            lambda: self.retry_handler.execute_async(
                _request,
                context={'service': self.service_name, 'endpoint': endpoint}
            )
        )
    
    async def put(
        self,
        endpoint: str,
        data: Optional[Union[Dict, List]] = None,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make PUT request with resilience"""
        async def _request():
            return await self._make_request(
                HTTPMethod.PUT, endpoint, data=data, params=params, headers=headers, **kwargs
            )
        
        return await self.circuit_breaker.call_async(
            lambda: self.retry_handler.execute_async(
                _request,
                context={'service': self.service_name, 'endpoint': endpoint}
            )
        )
    
    async def patch(
        self,
        endpoint: str,
        data: Optional[Union[Dict, List]] = None,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make PATCH request with resilience"""
        async def _request():
            return await self._make_request(
                HTTPMethod.PATCH, endpoint, data=data, params=params, headers=headers, **kwargs
            )
        
        return await self.circuit_breaker.call_async(
            lambda: self.retry_handler.execute_async(
                _request,
                context={'service': self.service_name, 'endpoint': endpoint}
            )
        )
    
    async def delete(
        self,
        endpoint: str,
        params: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> APIResponse:
        """Make DELETE request with resilience"""
        async def _request():
            return await self._make_request(
                HTTPMethod.DELETE, endpoint, params=params, headers=headers, **kwargs
            )
        
        return await self.circuit_breaker.call_async(
            lambda: self.retry_handler.execute_async(
                _request,
                context={'service': self.service_name, 'endpoint': endpoint}
            )
        )
    
    def get_stats(self) -> Dict[str, Any]:
        """Get client statistics"""
        return {
            'service_name': self.service_name,
            'base_url': self.base_url,
            'circuit_breaker_stats': self.circuit_breaker.get_stats(),
            'session_closed': self._session is None or self._session.closed
        }


class APIClientManager:
    """Manager for multiple API clients"""
    
    def __init__(self):
        self._clients: Dict[str, ResilientAPIClient] = {}
        self.logger = logging.getLogger("api_client_manager")
    
    def create_client(
        self,
        service_name: str,
        base_url: str,
        timeout: int = 30,
        retry_config: Optional[RetryHandler] = None,
        circuit_breaker_config: Optional[CircuitBreaker] = None,
        default_headers: Optional[Dict[str, str]] = None
    ) -> ResilientAPIClient:
        """Create and register a new API client"""
        
        if service_name in self._clients:
            self.logger.warning(f"API client for {service_name} already exists, replacing")
        
        client = ResilientAPIClient(
            base_url=base_url,
            service_name=service_name,
            timeout=timeout,
            retry_handler=retry_config,
            circuit_breaker=circuit_breaker_config,
            default_headers=default_headers
        )
        
        self._clients[service_name] = client
        
        self.logger.info(
            f"Created API client for {service_name}",
            extra={'service_name': service_name, 'base_url': base_url}
        )
        
        return client
    
    def get_client(self, service_name: str) -> Optional[ResilientAPIClient]:
        """Get existing API client"""
        return self._clients.get(service_name)
    
    async def close_all(self):
        """Close all API clients"""
        for client in self._clients.values():
            await client.close()
        self.logger.info("All API clients closed")
    
    def get_all_stats(self) -> Dict[str, Dict[str, Any]]:
        """Get statistics for all clients"""
        return {
            name: client.get_stats() 
            for name, client in self._clients.items()
        }


# Global API client manager
api_client_manager = APIClientManager()


# Convenience functions for common external services
async def create_openai_client() -> ResilientAPIClient:
    """Create OpenAI API client"""
    return api_client_manager.create_client(
        service_name="openai",
        base_url="https://api.openai.com/v1",
        timeout=60,
        retry_config=RetryHandler(RetryConfigs.AI_MODEL),
        default_headers={"Content-Type": "application/json"}
    )


async def create_anthropic_client() -> ResilientAPIClient:
    """Create Anthropic API client"""
    return api_client_manager.create_client(
        service_name="anthropic",
        base_url="https://api.anthropic.com/v1",
        timeout=60,
        retry_config=RetryHandler(RetryConfigs.AI_MODEL),
        default_headers={"Content-Type": "application/json"}
    )


async def create_sendgrid_client() -> ResilientAPIClient:
    """Create SendGrid API client"""
    return api_client_manager.create_client(
        service_name="sendgrid",
        base_url="https://api.sendgrid.com/v3",
        timeout=30,
        default_headers={"Content-Type": "application/json"}
    )


async def create_twilio_client() -> ResilientAPIClient:
    """Create Twilio API client"""
    return api_client_manager.create_client(
        service_name="twilio",
        base_url="https://api.twilio.com/2010-04-01",
        timeout=30,
        default_headers={"Content-Type": "application/x-www-form-urlencoded"}
    )