'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function GeneralSettingsPage() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [settings, setSettings] = useState({
    applicationName: 'FED-TMS',
    applicationLogo: '',
    supportEmail: 'support@fedtms.com',
    defaultCurrency: 'USD',
    defaultLocale: 'en-US',
    timezone: 'America/Chicago',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setSettings((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1000))
      addToast('General settings saved successfully', 'success')
    } catch (err) {
      addToast('Error saving settings', 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div>
        <Link href="/dashboard/admin/settings" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block text-sm">
          ← Back to Settings
        </Link>
        <h1 className="text-3xl font-bold">General Settings</h1>
        <p className="text-gray-400 mt-2">Configure basic application settings</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* APPLICATION INFO */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Application Information</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Application Name</label>
            <input
              type="text"
              name="applicationName"
              value={settings.applicationName}
              onChange={handleChange}
              placeholder="FED-TMS"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <p className="text-xs text-gray-400 mt-1">The name displayed throughout the application</p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Logo URL</label>
            <input
              type="text"
              name="applicationLogo"
              value={settings.applicationLogo}
              onChange={handleChange}
              placeholder="https://example.com/logo.png"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <p className="text-xs text-gray-400 mt-1">URL to your application logo</p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Support Email</label>
            <input
              type="email"
              name="supportEmail"
              value={settings.supportEmail}
              onChange={handleChange}
              placeholder="support@example.com"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <p className="text-xs text-gray-400 mt-1">Email address for customer support inquiries</p>
          </div>
        </div>

        {/* LOCALIZATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Localization</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Currency</label>
              <select
                name="defaultCurrency"
                value={settings.defaultCurrency}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option value="USD">USD - US Dollar</option>
                <option value="EUR">EUR - Euro</option>
                <option value="GBP">GBP - British Pound</option>
                <option value="CAD">CAD - Canadian Dollar</option>
                <option value="AUD">AUD - Australian Dollar</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">Language</label>
              <select
                name="defaultLocale"
                value={settings.defaultLocale}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option value="en-US">English (US)</option>
                <option value="en-GB">English (UK)</option>
                <option value="es-ES">Spanish</option>
                <option value="fr-FR">French</option>
                <option value="de-DE">German</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Timezone</label>
            <select
              name="timezone"
              value={settings.timezone}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option value="America/New_York">Eastern Time (ET)</option>
              <option value="America/Chicago">Central Time (CT)</option>
              <option value="America/Denver">Mountain Time (MT)</option>
              <option value="America/Los_Angeles">Pacific Time (PT)</option>
              <option value="America/Anchorage">Alaska Time (AKT)</option>
              <option value="Pacific/Honolulu">Hawaii Time (HT)</option>
            </select>
            <p className="text-xs text-gray-400 mt-1">Default timezone for the application</p>
          </div>
        </div>

        {/* FEATURE FLAGS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Feature Flags</h2>

          <div className="space-y-3">
            <label className="flex items-center gap-3 p-4 bg-white/5 rounded-lg border border-white/10 cursor-pointer hover:bg-white/10 transition-colors">
              <input
                type="checkbox"
                defaultChecked
                className="w-4 h-4 rounded accent-[#d946ef]"
              />
              <div>
                <p className="font-semibold text-sm">Analytics Module</p>
                <p className="text-xs text-gray-400">Enable analytics and reporting features</p>
              </div>
            </label>

            <label className="flex items-center gap-3 p-4 bg-white/5 rounded-lg border border-white/10 cursor-pointer hover:bg-white/10 transition-colors">
              <input
                type="checkbox"
                defaultChecked
                className="w-4 h-4 rounded accent-[#d946ef]"
              />
              <div>
                <p className="font-semibold text-sm">Notifications</p>
                <p className="text-xs text-gray-400">Enable notification system</p>
              </div>
            </label>

            <label className="flex items-center gap-3 p-4 bg-white/5 rounded-lg border border-white/10 cursor-pointer hover:bg-white/10 transition-colors">
              <input
                type="checkbox"
                className="w-4 h-4 rounded accent-[#d946ef]"
              />
              <div>
                <p className="font-semibold text-sm">API v2 (Beta)</p>
                <p className="text-xs text-gray-400">Enable experimental API v2 endpoints</p>
              </div>
            </label>
          </div>
        </div>

        {/* INFO */}
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>ℹ️ Note:</strong> Changes to general settings apply immediately to all users. Some settings may require a page refresh to take effect.
          </p>
        </div>

        {/* ACTIONS */}
        <div className="flex gap-4">
          <button
            type="submit"
            disabled={loading}
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Saving...' : 'Save Changes'}
          </button>
          <Link
            href="/dashboard/admin/settings"
            className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center"
          >
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}
