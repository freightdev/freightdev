'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { useNotificationPreferences } from '@/lib/hooks/useNotifications'

export default function NotificationPreferencesPage() {
  const { settings, updateSettings, loading, error } = useNotificationPreferences()

  const [emailNotifications, setEmailNotifications] = useState(true)
  const [pushNotifications, setPushNotifications] = useState(true)
  const [smsNotifications, setSmsNotifications] = useState(false)
  const [frequency, setFrequency] = useState<'immediate' | 'hourly' | 'daily' | 'weekly'>('immediate')
  const [enabledTypes, setEnabledTypes] = useState({
    loads: true,
    carriers: true,
    payments: true,
    system: true,
    messages: true,
  })
  const [saveMessage, setSaveMessage] = useState('')
  const [isSaving, setIsSaving] = useState(false)

  useEffect(() => {
    if (settings) {
      setEmailNotifications(settings.emailNotifications)
      setPushNotifications(settings.pushNotifications)
      setSmsNotifications(settings.smsNotifications)
      setFrequency(settings.notificationFrequency)
      setEnabledTypes(settings.enabledTypes)
    }
  }, [settings])

  const handleSave = async () => {
    setIsSaving(true)
    try {
      await updateSettings({
        emailNotifications,
        pushNotifications,
        smsNotifications,
        notificationFrequency: frequency,
        enabledTypes,
      })
      setSaveMessage('Preferences saved successfully!')
      setTimeout(() => setSaveMessage(''), 3000)
    } catch (err) {
      setSaveMessage('Failed to save preferences')
      console.error('Error saving preferences:', err)
    } finally {
      setIsSaving(false)
    }
  }

  const handleTypeToggle = (type: keyof typeof enabledTypes) => {
    setEnabledTypes((prev) => ({
      ...prev,
      [type]: !prev[type],
    }))
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div>
        <div className="flex items-center gap-3 mb-2">
          <Link href="/dashboard/notifications" className="text-gray-400 hover:text-white transition-colors">
            Notifications
          </Link>
          <span className="text-gray-600">/</span>
          <span className="text-white">Preferences</span>
        </div>
        <h1 className="text-3xl font-bold">Notification Preferences</h1>
        <p className="text-gray-400 mt-2">Manage how and when you receive notifications</p>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="text-center py-12">
          <p className="text-gray-400">Loading preferences...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading preferences: {error}</p>
        </div>
      )}

      {!loading && (
        <>
          {/* NOTIFICATION CHANNELS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Notification Channels</h2>
            <p className="text-sm text-gray-400">Choose how you want to receive notifications</p>

            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">Email Notifications</p>
                  <p className="text-sm text-gray-400">Receive notifications via email</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={emailNotifications}
                    onChange={(e) => setEmailNotifications(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">Push Notifications</p>
                  <p className="text-sm text-gray-400">Receive push notifications on your devices</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={pushNotifications}
                    onChange={(e) => setPushNotifications(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">SMS Notifications</p>
                  <p className="text-sm text-gray-400">Receive text messages for urgent notifications</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={smsNotifications}
                    onChange={(e) => setSmsNotifications(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                </label>
              </div>
            </div>
          </div>

          {/* NOTIFICATION FREQUENCY */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Notification Frequency</h2>
            <p className="text-sm text-gray-400">Control how often you receive notifications</p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {[
                { value: 'immediate', label: 'Immediate', description: 'Get notified right away' },
                {
                  value: 'hourly',
                  label: 'Hourly Digest',
                  description: 'Receive a summary every hour',
                },
                {
                  value: 'daily',
                  label: 'Daily Digest',
                  description: 'Receive a summary every day',
                },
                {
                  value: 'weekly',
                  label: 'Weekly Digest',
                  description: 'Receive a summary every week',
                },
              ].map((option) => (
                <button
                  key={option.value}
                  onClick={() => setFrequency(option.value as typeof frequency)}
                  className={`p-4 rounded-lg border transition-all text-left ${
                    frequency === option.value
                      ? 'bg-blue-500/20 border-blue-500/50'
                      : 'bg-white/5 border-white/10 hover:border-white/20'
                  }`}
                >
                  <p className={`font-semibold ${frequency === option.value ? 'text-blue-400' : 'text-white'}`}>
                    {option.label}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">{option.description}</p>
                </button>
              ))}
            </div>
          </div>

          {/* NOTIFICATION TYPES */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Notification Types</h2>
            <p className="text-sm text-gray-400">Choose which types of notifications you want to receive</p>

            <div className="space-y-3">
              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">📦 Load Notifications</p>
                  <p className="text-sm text-gray-400">New loads, assignments, delivery updates</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabledTypes.loads}
                    onChange={() => handleTypeToggle('loads')}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">🚚 Carrier Notifications</p>
                  <p className="text-sm text-gray-400">Carrier status, ratings, compliance updates</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabledTypes.carriers}
                    onChange={() => handleTypeToggle('carriers')}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">💳 Payment Notifications</p>
                  <p className="text-sm text-gray-400">Commission payments, invoice updates</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabledTypes.payments}
                    onChange={() => handleTypeToggle('payments')}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">⚙️ System Notifications</p>
                  <p className="text-sm text-gray-400">System updates, maintenance alerts</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabledTypes.system}
                    onChange={() => handleTypeToggle('system')}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
                </label>
              </div>

              <div className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
                <div>
                  <p className="font-semibold text-white">💬 Message Notifications</p>
                  <p className="text-sm text-gray-400">New messages and chat updates</p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enabledTypes.messages}
                    onChange={() => handleTypeToggle('messages')}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-white/20 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-800 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-600"></div>
                </label>
              </div>
            </div>
          </div>

          {/* SUCCESS/ERROR MESSAGES */}
          {saveMessage && (
            <div
              className={`rounded-xl p-6 border ${
                saveMessage.includes('success')
                  ? 'bg-green-500/10 border-green-500/30 text-green-400'
                  : 'bg-red-500/10 border-red-500/30 text-red-400'
              }`}
            >
              <p className="text-sm">{saveMessage}</p>
            </div>
          )}

          {/* SAVE BUTTON */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="px-6 py-3 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-blue-500/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSaving ? 'Saving...' : 'Save Preferences'}
            </button>
            <p className="text-xs text-gray-400 mt-3">
              Your preferences are saved automatically and applied immediately.
            </p>
          </div>

          {/* INFO CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
              <p className="text-sm text-blue-400">
                <strong>💡 Tip:</strong> Using digests can help reduce notification overload while
                keeping you informed about important updates.
              </p>
            </div>
            <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-6">
              <p className="text-sm text-green-400">
                <strong>✅ Note:</strong> You can always view missed notifications in the notification
                center. Important alerts will still be sent immediately.
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
