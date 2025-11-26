/**
 * WebSocket Service for Real-time Updates
 * Handles notifications, messages, and presence updates
 */

export type WebSocketMessageType =
  | 'notification'
  | 'message'
  | 'presence'
  | 'typing'
  | 'read'
  | 'connection'
  | 'error'

export interface WebSocketMessage {
  type: WebSocketMessageType
  data: any
  timestamp: string
}

export interface WebSocketEventHandlers {
  onNotification?: (data: any) => void
  onMessage?: (data: any) => void
  onPresence?: (data: any) => void
  onTyping?: (data: any) => void
  onRead?: (data: any) => void
  onError?: (error: Error) => void
  onConnect?: () => void
  onDisconnect?: () => void
}

class WebSocketService {
  private ws: WebSocket | null = null
  private url: string
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectDelay = 3000
  private isManualClose = false
  private handlers: WebSocketEventHandlers = {}
  private messageQueue: WebSocketMessage[] = []
  private heartbeatInterval: NodeJS.Timeout | null = null

  constructor(url: string = '') {
    this.url = url || this.getWebSocketURL()
  }

  private getWebSocketURL(): string {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = window.location.host
    return `${protocol}//${host}/api/ws`
  }

  /**
   * Connect to WebSocket server
   */
  public connect(handlers?: WebSocketEventHandlers): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        if (this.handlers) {
          this.handlers = { ...this.handlers, ...handlers }
        } else {
          this.handlers = handlers || {}
        }

        this.ws = new WebSocket(this.url)

        this.ws.onopen = () => {
          console.log('WebSocket connected')
          this.reconnectAttempts = 0
          this.startHeartbeat()
          this.flushMessageQueue()
          this.handlers.onConnect?.()
          resolve()
        }

        this.ws.onmessage = (event) => {
          try {
            const message: WebSocketMessage = JSON.parse(event.data)
            this.handleMessage(message)
          } catch (error) {
            console.error('Failed to parse WebSocket message:', error)
          }
        }

        this.ws.onerror = (event) => {
          const error = new Error('WebSocket error occurred')
          console.error('WebSocket error:', error)
          this.handlers.onError?.(error)
          reject(error)
        }

        this.ws.onclose = () => {
          console.log('WebSocket disconnected')
          this.stopHeartbeat()
          this.handlers.onDisconnect?.()

          if (!this.isManualClose && this.reconnectAttempts < this.maxReconnectAttempts) {
            const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts)
            setTimeout(() => {
              this.reconnectAttempts++
              this.connect(handlers)
            }, delay)
          }
        }
      } catch (error) {
        reject(error)
      }
    })
  }

  /**
   * Disconnect from WebSocket server
   */
  public disconnect(): void {
    this.isManualClose = true
    this.stopHeartbeat()
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
  }

  /**
   * Send a message through WebSocket
   */
  public send(type: WebSocketMessageType, data: any): void {
    const message: WebSocketMessage = {
      type,
      data,
      timestamp: new Date().toISOString(),
    }

    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message))
    } else {
      // Queue message if not connected
      this.messageQueue.push(message)
    }
  }

  /**
   * Send notification read acknowledgment
   */
  public sendNotificationRead(notificationId: string): void {
    this.send('read', { type: 'notification', id: notificationId })
  }

  /**
   * Send message read acknowledgment
   */
  public sendMessageRead(conversationId: string, messageId: string): void {
    this.send('read', { type: 'message', conversationId, messageId })
  }

  /**
   * Send typing indicator
   */
  public sendTyping(conversationId: string, isTyping: boolean): void {
    this.send('typing', { conversationId, isTyping })
  }

  /**
   * Update presence status
   */
  public updatePresence(status: 'online' | 'away' | 'offline'): void {
    this.send('presence', { status })
  }

  /**
   * Register event handler
   */
  public on(event: string, handler: (data: any) => void): void {
    if (event === 'notification') {
      this.handlers.onNotification = handler
    } else if (event === 'message') {
      this.handlers.onMessage = handler
    } else if (event === 'presence') {
      this.handlers.onPresence = handler
    } else if (event === 'typing') {
      this.handlers.onTyping = handler
    } else if (event === 'read') {
      this.handlers.onRead = handler
    }
  }

  /**
   * Handle incoming WebSocket message
   */
  private handleMessage(message: WebSocketMessage): void {
    switch (message.type) {
      case 'notification':
        this.handlers.onNotification?.(message.data)
        break
      case 'message':
        this.handlers.onMessage?.(message.data)
        break
      case 'presence':
        this.handlers.onPresence?.(message.data)
        break
      case 'typing':
        this.handlers.onTyping?.(message.data)
        break
      case 'read':
        this.handlers.onRead?.(message.data)
        break
      case 'error':
        this.handlers.onError?.(new Error(message.data?.message || 'Unknown error'))
        break
      default:
        console.warn(`Unknown message type: ${message.type}`)
    }
  }

  /**
   * Flush queued messages
   */
  private flushMessageQueue(): void {
    while (this.messageQueue.length > 0) {
      const message = this.messageQueue.shift()
      if (message && this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify(message))
      }
    }
  }

  /**
   * Start heartbeat to keep connection alive
   */
  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.send('connection', { type: 'ping' })
      }
    }, 30000) // Send ping every 30 seconds
  }

  /**
   * Stop heartbeat
   */
  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }
  }

  /**
   * Check if connected
   */
  public isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN
  }

  /**
   * Get connection state
   */
  public getState(): string {
    if (!this.ws) return 'CLOSED'
    switch (this.ws.readyState) {
      case WebSocket.CONNECTING:
        return 'CONNECTING'
      case WebSocket.OPEN:
        return 'OPEN'
      case WebSocket.CLOSING:
        return 'CLOSING'
      case WebSocket.CLOSED:
        return 'CLOSED'
      default:
        return 'UNKNOWN'
    }
  }
}

// Export singleton instance
export const webSocketService = new WebSocketService()

// For testing/development: export class for multiple instances
export default WebSocketService
