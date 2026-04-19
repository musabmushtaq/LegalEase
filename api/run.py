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
        print("\n🛑 Shutting down API server...")
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
        """Listen for 'q' key press in console."""
        try:
            while not self.should_exit:
                try:
                    key = input()
                    if key.lower() == 'q':
                        self.should_exit = True
                        print("\n🛑 Shutting down API server (q pressed)...")
                        if self.server:
                            self.server.should_exit = True
                        break
                except EOFError:
                    # End of input, don't crash
                    pass
        except KeyboardInterrupt:
            pass


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
    
    # Register signal handlers
    signal.signal(signal.SIGINT, shutdown.signal_handler)
    signal.signal(signal.SIGTERM, shutdown.signal_handler)
    
    # Start listener thread for 'q' key (daemon thread so it doesn't block exit)
    listener_thread = threading.Thread(target=shutdown.listen_for_q, daemon=True)
    listener_thread.start()
    
    print("=" * 60)
    print("🚀 LegalEase API Server Starting...")
    print("=" * 60)
    print("Press Ctrl+C or 'q' to gracefully shut down")
    print("=" * 60)
    
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
