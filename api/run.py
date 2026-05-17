#!/usr/bin/env python
"""
LegalEase API Runner with graceful shutdown.
Handles Ctrl+C without hanging.
"""

import signal
import sys
import uvicorn
from typing import Any


class GracefulShutdown:
    def __init__(self):
        self.server: uvicorn.Server | None = None

    def signal_handler(self, signum: int, frame: Any) -> None:
        """Handle Ctrl+C gracefully."""
        if self.server:
            self.server.should_exit = True


async def main():
    """Start the API server with graceful shutdown."""
    config = uvicorn.Config(
        app="main:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True,
    )
    
    server = uvicorn.Server(config)
    shutdown = GracefulShutdown()
    shutdown.server = server
    
    # Register signal handlers for Ctrl+C
    signal.signal(signal.SIGINT, shutdown.signal_handler)
    signal.signal(signal.SIGTERM, shutdown.signal_handler)
    
    try:
        await server.serve()
    except KeyboardInterrupt:
        print("\n✅ API server shut down gracefully")
        sys.exit(0)


if __name__ == "__main__":
    import asyncio
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n✅ API server shut down gracefully")
        sys.exit(0)
