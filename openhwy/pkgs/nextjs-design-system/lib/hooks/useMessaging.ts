import { useState, useEffect, useCallback } from 'react'

export interface Message {
  id: string
  conversationId: string
  senderId: string
  senderName: string
  senderAvatar?: string
  content: string
  timestamp: string
  read: boolean
  attachments?: Array<{
    id: string
    name: string
    size: number
    type: string
    url: string
  }>
  edited?: boolean
  editedAt?: string
}

export interface Conversation {
  id: string
  name: string
  type: 'direct' | 'group'
  participants: Array<{
    id: string
    name: string
    avatar?: string
    status: 'online' | 'offline' | 'away'
  }>
  lastMessage?: Message
  unreadCount: number
  createdAt: string
  updatedAt: string
  avatar?: string
}

export interface ConversationsResponse {
  conversations: Conversation[]
  total: number
  page: number
  pageSize: number
}

export interface MessagesResponse {
  messages: Message[]
  total: number
  page: number
  pageSize: number
}

/**
 * Hook for fetching user conversations/chats
 */
export function useConversations(page: number = 1, pageSize: number = 20) {
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [unreadTotal, setUnreadTotal] = useState(0)
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchConversations = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(`/api/messages/conversations?page=${page}&pageSize=${pageSize}`)

        if (!response.ok) {
          throw new Error('Failed to fetch conversations')
        }

        const data: ConversationsResponse = await response.json()
        setConversations(data.conversations)
        setUnreadTotal(data.conversations.reduce((sum, c) => sum + c.unreadCount, 0))
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchConversations()
  }, [page, pageSize])

  return { conversations, unreadTotal, total, loading, error }
}

/**
 * Hook for fetching messages in a specific conversation
 */
export function useConversationMessages(conversationId: string, page: number = 1, pageSize: number = 50) {
  const [messages, setMessages] = useState<Message[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchMessages = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(
          `/api/messages/conversations/${conversationId}/messages?page=${page}&pageSize=${pageSize}`
        )

        if (!response.ok) {
          throw new Error('Failed to fetch messages')
        }

        const data: MessagesResponse = await response.json()
        setMessages(data.messages)
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    if (conversationId) {
      fetchMessages()
    }
  }, [conversationId, page, pageSize])

  return { messages, total, loading, error }
}

/**
 * Hook for sending and managing messages
 */
export function useMessageActions() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const sendMessage = useCallback(
    async (conversationId: string, content: string, attachments?: File[]) => {
      setLoading(true)
      setError(null)

      try {
        const formData = new FormData()
        formData.append('content', content)

        if (attachments) {
          attachments.forEach((file, index) => {
            formData.append(`attachments[${index}]`, file)
          })
        }

        const response = await fetch(`/api/messages/conversations/${conversationId}/send`, {
          method: 'POST',
          body: formData,
        })

        if (!response.ok) {
          throw new Error('Failed to send message')
        }

        return await response.json()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  const editMessage = useCallback(
    async (conversationId: string, messageId: string, content: string) => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch(
          `/api/messages/conversations/${conversationId}/messages/${messageId}`,
          {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ content }),
          }
        )

        if (!response.ok) {
          throw new Error('Failed to edit message')
        }

        return await response.json()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  const deleteMessage = useCallback(
    async (conversationId: string, messageId: string) => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch(
          `/api/messages/conversations/${conversationId}/messages/${messageId}`,
          {
            method: 'DELETE',
          }
        )

        if (!response.ok) {
          throw new Error('Failed to delete message')
        }

        return await response.json()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  const markAsRead = useCallback(
    async (conversationId: string) => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch(
          `/api/messages/conversations/${conversationId}/read`,
          {
            method: 'PATCH',
          }
        )

        if (!response.ok) {
          throw new Error('Failed to mark conversation as read')
        }

        return await response.json()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  return { sendMessage, editMessage, deleteMessage, markAsRead, loading, error }
}

/**
 * Hook for creating new conversations
 */
export function useCreateConversation() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const createDirectConversation = useCallback(async (userId: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/messages/conversations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'direct', participantId: userId }),
      })

      if (!response.ok) {
        throw new Error('Failed to create conversation')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  const createGroupConversation = useCallback(
    async (name: string, participantIds: string[]) => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch('/api/messages/conversations', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'group', name, participantIds }),
        })

        if (!response.ok) {
          throw new Error('Failed to create group conversation')
        }

        return await response.json()
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  return { createDirectConversation, createGroupConversation, loading, error }
}

/**
 * Hook for searching messages
 */
export function useMessageSearch(query: string = '', conversationId?: string) {
  const [results, setResults] = useState<Message[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!query) {
      setResults([])
      return
    }

    const searchMessages = async () => {
      try {
        setLoading(true)
        setError(null)

        const params = new URLSearchParams()
        params.append('q', query)
        if (conversationId) params.append('conversationId', conversationId)

        const response = await fetch(`/api/messages/search?${params}`)

        if (!response.ok) {
          throw new Error('Failed to search messages')
        }

        const data: Message[] = await response.json()
        setResults(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    const debounceTimer = setTimeout(searchMessages, 300)
    return () => clearTimeout(debounceTimer)
  }, [query, conversationId])

  return { results, loading, error }
}
