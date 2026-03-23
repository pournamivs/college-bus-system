from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        self.bus_connections: dict[str, list[WebSocket]] = {}
        self.admin_connections: list[WebSocket] = []

    async def connect_bus(self, websocket: WebSocket, bus_id: str):
        await websocket.accept()
        if bus_id not in self.bus_connections:
            self.bus_connections[bus_id] = []
        self.bus_connections[bus_id].append(websocket)

    def disconnect_bus(self, websocket: WebSocket, bus_id: str):
        if bus_id in self.bus_connections and websocket in self.bus_connections[bus_id]:
            self.bus_connections[bus_id].remove(websocket)

    async def connect_admin(self, websocket: WebSocket):
        await websocket.accept()
        self.admin_connections.append(websocket)

    def disconnect_admin(self, websocket: WebSocket):
        if websocket in self.admin_connections:
            self.admin_connections.remove(websocket)

    async def broadcast_bus(self, bus_id: str, message: str, exclude: WebSocket = None):
        for connection in self.bus_connections.get(bus_id, []):
            if connection != exclude:
                await connection.send_text(message)

    async def broadcast_admin(self, data: dict):
        for connection in list(self.admin_connections):
            try:
                await connection.send_json(data)
            except Exception:
                self.admin_connections.remove(connection)

manager = ConnectionManager()
