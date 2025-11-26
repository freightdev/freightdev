// API Hooks
export { useApi } from './useApi'
export type { ApiResponse } from './useApi'

// List Data Hooks
export { useDrivers } from './useDrivers'
export type { Driver as DriverType } from './useDrivers'

export { useLoads } from './useLoads'
export type { Load as LoadType } from './useLoads'

export { useInvoices } from './useInvoices'
export type { Invoice as InvoiceType } from './useInvoices'

// Detail Data Hooks
export { useDriver } from './useDriver'
export { useLoad } from './useLoad'
export { useInvoice } from './useInvoice'

// Form Submission Hooks
export {
  useDispatcherAgreementForm,
  useCarrierForm,
  useBrokerAgreementForm,
  useOperationalForm,
  useFinancialForm,
  useComplianceForm,
  useFormSubmission,
} from './useForms'
export type { FormSubmissionResponse, FormError } from './useForms'

// Admin Hooks
export { useUsers, useUser, useUserManagement } from './useUsers'
export type { User, UserFormData, UsersResponse } from './useUsers'

export { useCarriers, useCarrier, useCarrierManagement } from './useCarriers'
export type { Carrier, CarrierFormData, CarriersResponse } from './useCarriers'

export { useAdminSettings, useUpdateAdminSettings } from './useAdminSettings'
export type { AdminSettings } from './useAdminSettings'

export { useAuditLogs, useAuditLog, useExportAuditLogs, useSearchAuditLogs } from './useAuditLogs'
export type { AuditLog, AuditLogsResponse } from './useAuditLogs'

// Analytics Hooks
export {
  useAnalytics,
  useRevenueAnalytics,
  useLoadAnalytics,
  useCarrierAnalytics,
  useReportGeneration,
  useScheduledReports,
} from './useAnalytics'
export type {
  AnalyticsData,
  RevenueMetrics,
  LoadMetrics,
  CarrierMetrics,
  ReportFilters,
} from './useAnalytics'

// Notification Hooks
export {
  useNotifications,
  useNotificationActions,
  useNotificationPreferences,
  useNotificationSearch,
} from './useNotifications'
export type {
  Notification,
  NotificationsResponse,
  NotificationSettings,
} from './useNotifications'

// Messaging Hooks
export {
  useConversations,
  useConversationMessages,
  useMessageActions,
  useCreateConversation,
  useMessageSearch,
} from './useMessaging'
export type {
  Message,
  Conversation,
  ConversationsResponse,
  MessagesResponse,
} from './useMessaging'
