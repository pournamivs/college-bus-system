from fastapi import WebSocket
from typing import List, Dict

class ConnectionManager:
    def __init__(self):
        self.active_buses: Dict[str, List[WebSocket]] = {}
        self.admin_connections: List[WebSocket] = []

    async def connect_bus(self, websocket: WebSocket, bus_id: str):
        await websocket.accept()
        if bus_id not in self.active_buses:
            self.active_buses[bus_id] = []
        self.active_buses[bus_id].append(websocket)

    def disconnect_bus(self, websocket: WebSocket, bus_id: str):
        if bus_id in self.active_buses and websocket in self.active_buses[bus_id]:
            self.active_buses[bus_id].remove(websocket)

    async def broadcast_bus(self, bus_id: str, message: str):
        # Broadcast to anyone tracking this bus
        if bus_id in self.active_buses:
            disconnected = []
            for connection in self.active_buses[bus_id]:
                try:
                    await connection.send_text(message)
                except Exception:
                    disconnected.append(connection)
            for d in disconnected:
                self.active_buses[bus_id].remove(d)
        
        # Broadcast to all admins securely natively
        disconnected_admins = []
        for admin in self.admin_connections:
            try:
                await admin.send_text(message)
            except Exception:
                disconnected_admins.append(admin)
        for d in disconnected_admins:
            self.admin_connections.remove(d)

    async def connect_admin(self, websocket: WebSocket):
        await websocket.accept()
        self.admin_connections.append(websocket)

    def disconnect_admin(self, websocket: WebSocket):
        if websocket in self.admin_connections:
            self.admin_connections.remove(websocket)

manager = ConnectionManager()
