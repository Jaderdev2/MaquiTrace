import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { TrackingService } from './tracking.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: 'tracking',
})
export class TrackingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly trackingService: TrackingService) {}

  handleConnection(client: Socket) {
    // Cliente conectado a la telemetría en tiempo real
  }

  handleDisconnect(client: Socket) {
    // Cliente desconectado
  }

  @SubscribeMessage('joinTrip')
  handleJoinTrip(
    @MessageBody() tripId: string,
    @ConnectedSocket() client: Socket,
  ) {
    client.join(`trip_${tripId}`);
    return { event: 'joinedTrip', tripId };
  }

  // Notificar actualización de ubicación en vivo mediante el evento location:update
  broadcastLocationUpdate(tripId: string, locationData: any) {
    this.server.to(`trip_${tripId}`).emit('location:update', locationData);
    this.server.emit('location:update', locationData);
  }
}
