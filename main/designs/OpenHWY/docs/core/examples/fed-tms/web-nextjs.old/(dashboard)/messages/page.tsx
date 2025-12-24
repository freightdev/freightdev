'use client'

import React, { useState, useRef, useEffect } from 'react'
import Link from 'next/link'
import { useConversations, useConversationMessages, useMessageActions } from '@/lib/hooks/useMessaging'

export default function MessagesPage() {
  const [selectedConversationId, setSelectedConversationId] = useState<string | null>(null)
  const [messageText, setMessageText] = useState('')
  const [currentPage, setCurrentPage] = useState(1)
  const [searchQuery, setSearchQuery] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)

  const { conversations, unreadTotal, total, loading, error } = useConversations(currentPage)
  const { messages, total: totalMessages, loading: messagesLoading } = useConversationMessages(
    selectedConversationId || '',
    1,
    50
  )
  const { sendMessage, loading: sendingMessage } = useMessageActions()

  // Auto-select first conversation if none selected
  useEffect(() => {
    if (conversations.length > 0 && !selectedConversationId) {
      setSelectedConversationId(conversations[0].id)
    }
  }, [conversations, selectedConversationId])

  // Scroll to bottom when new messages arrive
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const filteredConversations = searchQuery
    ? conversations.filter(
        (c) =>
          c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          c.participants.some((p) => p.name.toLowerCase().includes(searchQuery.toLowerCase()))
      )
    : conversations

  const selectedConversation = conversations.find((c) => c.id === selectedConversationId)

  const handleSendMessage = async () => {
    if (messageText.trim() && selectedConversationId) {
      const content = messageText
      setMessageText('')
      try {
        await sendMessage(selectedConversationId, content)
      } catch (err) {
        console.error('Failed to send message:', err)
      }
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return 'bg-green-500'
      case 'away':
        return 'bg-yellow-500'
      case 'offline':
        return 'bg-gray-500'
      default:
        return 'bg-gray-400'
    }
  }

  const getConversationPreview = (conversation: any) => {
    if (!conversation.lastMessage) return 'No messages yet'
    const maxLength = 40
    return conversation.lastMessage.content.length > maxLength
      ? conversation.lastMessage.content.substring(0, maxLength) + '...'
      : conversation.lastMessage.content
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Messages</h1>
          <p className="text-gray-400 mt-2">
            {unreadTotal} unread of {total} conversations
          </p>
        </div>
        <button className="px-4 py-2 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg text-white text-sm font-semibold hover:shadow-lg hover:shadow-blue-500/40 transition-all">
          + New Conversation
        </button>
      </div>

      <div className="grid grid-cols-4 gap-6 h-[calc(100vh-200px)]">
        {/* CONVERSATIONS LIST */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-4 flex flex-col overflow-hidden space-y-4">
          <div>
            <input
              type="text"
              placeholder="Search..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value)
                setCurrentPage(1)
              }}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-3 py-2 text-white placeholder-gray-500 text-sm focus:outline-none focus:border-blue-500/50 transition-colors"
            />
          </div>

          {loading && <p className="text-gray-400 text-sm">Loading...</p>}
          {error && <p className="text-red-400 text-sm">Error: {error}</p>}

          <div className="flex-1 space-y-2 overflow-y-auto">
            {filteredConversations.map((conversation) => (
              <button
                key={conversation.id}
                onClick={() => setSelectedConversationId(conversation.id)}
                className={`w-full text-left p-3 rounded-lg border transition-all ${
                  selectedConversationId === conversation.id
                    ? 'bg-blue-500/20 border-blue-500/50'
                    : 'bg-white/5 border-white/10 hover:border-white/20'
                }`}
              >
                <div className="flex items-center gap-2 mb-2">
                  <div className="relative flex-shrink-0 w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
                    <span className="text-xs font-bold text-white">
                      {conversation.name
                        .split(' ')
                        .map((n: string) => n[0])
                        .join('')
                        .substring(0, 2)
                        .toUpperCase()}
                    </span>
                    {conversation.type === 'direct' && conversation.participants[0] && (
                      <div
                        className={`absolute bottom-0 right-0 w-2 h-2 rounded-full border border-[#1a1a2e] ${getStatusColor(
                          conversation.participants[0].status
                        )}`}
                      />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-sm truncate">{conversation.name}</p>
                    <p className="text-xs text-gray-500 truncate">
                      {conversation.type === 'group' ? `${conversation.participants.length} participants` : conversation.participants[0]?.name}
                    </p>
                  </div>
                  {conversation.unreadCount > 0 && (
                    <span className="bg-blue-500 text-white text-xs font-bold px-2 py-1 rounded-full flex-shrink-0">
                      {conversation.unreadCount}
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-400 truncate">{getConversationPreview(conversation)}</p>
              </button>
            ))}
          </div>
        </div>

        {/* CHAT AREA */}
        <div className="col-span-3 bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 flex flex-col overflow-hidden">
          {selectedConversation ? (
            <>
              <div className="pb-4 border-b border-white/10 mb-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-xl font-bold">{selectedConversation.name}</h2>
                    <p className="text-sm text-gray-400">
                      {selectedConversation.type === 'group'
                        ? `${selectedConversation.participants.length} participants`
                        : selectedConversation.participants.map((p) => p.name).join(', ')}
                    </p>
                  </div>
                  {selectedConversation.type === 'direct' && selectedConversation.participants[0] && (
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-3 h-3 rounded-full ${getStatusColor(selectedConversation.participants[0].status)}`}
                      />
                      <span className="text-sm text-gray-400 capitalize">{selectedConversation.participants[0].status}</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="flex-1 overflow-y-auto space-y-4 mb-4 pb-4">
                {messagesLoading ? (
                  <p className="text-gray-400 text-center">Loading messages...</p>
                ) : messages.length === 0 ? (
                  <p className="text-gray-400 text-center">No messages yet. Start the conversation!</p>
                ) : (
                  messages.map((msg) => (
                    <div key={msg.id} className={`flex ${msg.senderId === 'current-user' ? 'justify-end' : 'justify-start'}`}>
                      <div
                        className={`max-w-xs px-4 py-2 rounded-lg ${
                          msg.senderId === 'current-user'
                            ? 'bg-blue-500/20 border border-blue-500/50'
                            : 'bg-white/10 border border-white/20'
                        }`}
                      >
                        {msg.senderId !== 'current-user' && <p className="text-xs font-semibold text-gray-300 mb-1">{msg.senderName}</p>}
                        <p className="text-sm">{msg.content}</p>
                        <p className="text-xs text-gray-400 mt-1">
                          {new Date(msg.timestamp).toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'})}
                        </p>
                      </div>
                    </div>
                  ))
                )}
                <div ref={messagesEndRef} />
              </div>

              <div className="flex gap-2 pt-4 border-t border-white/10">
                <input
                  type="text"
                  value={messageText}
                  onChange={(e) => setMessageText(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && !sendingMessage && handleSendMessage()}
                  placeholder="Type a message..."
                  disabled={sendingMessage}
                  className="flex-1 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-blue-500/50 transition-colors disabled:opacity-50"
                />
                <button
                  onClick={handleSendMessage}
                  disabled={sendingMessage || !messageText.trim()}
                  className="px-6 py-3 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-blue-500/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {sendingMessage ? '...' : 'Send'}
                </button>
              </div>
            </>
          ) : (
            <div className="flex items-center justify-center h-full">
              <p className="text-gray-400">Select a conversation to start chatting</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
