/**
 * Input Validation Schemas
 * Zod schemas for request body validation
 */

import { z } from 'zod'

// ============ AUTH SCHEMAS ============

export const RegisterSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  first_name: z.string().min(1, 'First name is required'),
  last_name: z.string().min(1, 'Last name is required'),
  company_name: z.string().optional(),
})

export type RegisterInput = z.infer<typeof RegisterSchema>

export const LoginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
})

export type LoginInput = z.infer<typeof LoginSchema>

export const RefreshTokenSchema = z.object({
  refresh_token: z.string().min(1, 'Refresh token is required'),
})

export type RefreshTokenInput = z.infer<typeof RefreshTokenSchema>

// ============ USER SCHEMAS ============

export const CreateUserSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  first_name: z.string().min(1, 'First name is required'),
  last_name: z.string().min(1, 'Last name is required'),
  phone: z.string().optional(),
  role_id: z.string().min(1, 'Role is required'),
})

export type CreateUserInput = z.infer<typeof CreateUserSchema>

export const UpdateUserSchema = z.object({
  email: z.string().email().optional(),
  first_name: z.string().min(1).optional(),
  last_name: z.string().min(1).optional(),
  phone: z.string().optional(),
  avatar_url: z.string().url().optional(),
})

export type UpdateUserInput = z.infer<typeof UpdateUserSchema>

export const UpdatePasswordSchema = z.object({
  current_password: z.string().min(1, 'Current password is required'),
  new_password: z.string().min(8, 'New password must be at least 8 characters'),
})

export type UpdatePasswordInput = z.infer<typeof UpdatePasswordSchema>

// ============ DRIVER SCHEMAS ============

export const CreateDriverSchema = z.object({
  user_id: z.string().min(1, 'User ID is required'),
  license_number: z.string().min(1, 'License number is required'),
  license_class: z.string().optional(),
  license_expiry: z.string().datetime().optional(),
  vehicle_type: z.string().optional(),
  vehicle_vin: z.string().optional(),
  vehicle_plate: z.string().optional(),
})

export type CreateDriverInput = z.infer<typeof CreateDriverSchema>

export const UpdateDriverSchema = z.object({
  license_number: z.string().optional(),
  license_class: z.string().optional(),
  license_expiry: z.string().datetime().optional(),
  vehicle_type: z.string().optional(),
  vehicle_vin: z.string().optional(),
  vehicle_plate: z.string().optional(),
  status: z.enum(['active', 'inactive', 'on_leave', 'suspended']).optional(),
})

export type UpdateDriverInput = z.infer<typeof UpdateDriverSchema>

export const CreateDriverDocumentSchema = z.object({
  type: z.enum(['license', 'insurance', 'medical_cert', 'background_check']),
  document_url: z.string().url('Invalid document URL'),
  expiry_date: z.string().datetime().optional(),
})

export type CreateDriverDocumentInput = z.infer<typeof CreateDriverDocumentSchema>

export const UpdateLocationSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy: z.number().optional(),
})

export type UpdateLocationInput = z.infer<typeof UpdateLocationSchema>

export const CreateRatingSchema = z.object({
  rating: z.number().min(1).max(5),
  comment: z.string().optional(),
  load_id: z.string().optional(),
})

export type CreateRatingInput = z.infer<typeof CreateRatingSchema>

// ============ LOAD SCHEMAS ============

export const CreateLoadSchema = z.object({
  reference_number: z.string().min(1, 'Reference number is required'),
  pickup_address: z.string().min(1),
  pickup_city: z.string().min(1),
  pickup_state: z.string().min(1),
  pickup_zip: z.string().min(1),
  pickup_date: z.string().datetime(),
  delivery_address: z.string().min(1),
  delivery_city: z.string().min(1),
  delivery_state: z.string().min(1),
  delivery_zip: z.string().min(1),
  delivery_date: z.string().datetime(),
  commodity: z.string().optional(),
  weight: z.number().optional(),
  dimensions: z.string().optional(),
  hazmat: z.boolean().default(false),
  special_handling: z.string().optional(),
  rate: z.number().min(0),
})

export type CreateLoadInput = z.infer<typeof CreateLoadSchema>

export const UpdateLoadSchema = z.object({
  status: z.enum(['pending', 'accepted', 'in_transit', 'delivered', 'cancelled']).optional(),
  pickup_date: z.string().datetime().optional(),
  delivery_date: z.string().datetime().optional(),
  rate: z.number().min(0).optional(),
  commodity: z.string().optional(),
  weight: z.number().optional(),
  special_handling: z.string().optional(),
})

export type UpdateLoadInput = z.infer<typeof UpdateLoadSchema>

export const AssignLoadSchema = z.object({
  driver_id: z.string().min(1, 'Driver ID is required'),
})

export type AssignLoadInput = z.infer<typeof AssignLoadSchema>

export const UpdateAssignmentSchema = z.object({
  status: z.enum(['pending', 'accepted', 'rejected', 'completed']).optional(),
})

export type UpdateAssignmentInput = z.infer<typeof UpdateAssignmentSchema>

export const UpdateTrackingSchema = z.object({
  status: z.enum([
    'pickup_arrived',
    'pickup_completed',
    'in_transit',
    'delivery_arrived',
    'delivered',
    'failed',
  ]),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  notes: z.string().optional(),
})

export type UpdateTrackingInput = z.infer<typeof UpdateTrackingSchema>

// ============ PAYMENT SCHEMAS ============

export const CreateInvoiceSchema = z.object({
  invoice_number: z.string().min(1),
  driver_id: z.string().optional(),
  load_id: z.string().optional(),
  amount: z.number().min(0),
  due_date: z.string().datetime(),
  description: z.string().optional(),
  notes: z.string().optional(),
})

export type CreateInvoiceInput = z.infer<typeof CreateInvoiceSchema>

export const UpdateInvoiceSchema = z.object({
  status: z.enum(['pending', 'sent', 'partial', 'paid', 'overdue', 'cancelled']).optional(),
  amount: z.number().min(0).optional(),
  due_date: z.string().datetime().optional(),
})

export type UpdateInvoiceInput = z.infer<typeof UpdateInvoiceSchema>

export const CreatePaymentSchema = z.object({
  invoice_id: z.string().optional(),
  amount: z.number().min(0),
  method: z.enum(['card', 'ach', 'wire', 'check', 'cash']),
  transaction_id: z.string().optional(),
})

export type CreatePaymentInput = z.infer<typeof CreatePaymentSchema>

export const UpdatePaymentSchema = z.object({
  amount: z.number().min(0).optional(),
  method: z.enum(['card', 'ach', 'wire', 'check', 'cash']).optional(),
  status: z.enum(['pending', 'completed', 'failed', 'refunded']).optional(),
  transaction_id: z.string().optional(),
})

export type UpdatePaymentInput = z.infer<typeof UpdatePaymentSchema>

export const AddPaymentMethodSchema = z.object({
  type: z.enum(['card', 'ach', 'bank_account']),
  is_default: z.boolean().default(false),
  card_last4: z.string().optional(),
  card_brand: z.string().optional(),
  card_expiry: z.string().optional(),
  bank_account: z.string().optional(),
  bank_routing: z.string().optional(),
})

export type AddPaymentMethodInput = z.infer<typeof AddPaymentMethodSchema>

// ============ COMMUNICATION SCHEMAS ============

export const CreateConversationSchema = z.object({
  name: z.string().optional(),
  is_group: z.boolean().default(false),
  participant_ids: z.array(z.string()).optional(),
})

export type CreateConversationInput = z.infer<typeof CreateConversationSchema>

export const SendMessageSchema = z.object({
  content: z.string().min(1, 'Message cannot be empty'),
  recipient_id: z.string().optional(),
  message_type: z.enum(['text', 'image', 'file', 'system']).default('text'),
  attachment_url: z.string().url().optional(),
})

export type SendMessageInput = z.infer<typeof SendMessageSchema>

export const UpdateMessageSchema = z.object({
  content: z.string().min(1, 'Message cannot be empty'),
})

export type UpdateMessageInput = z.infer<typeof UpdateMessageSchema>

// ============ NOTIFICATION SCHEMAS ============

export const CreateNotificationSchema = z.object({
  user_id: z.string().min(1, 'User ID is required'),
  type: z.enum(['assignment', 'payment', 'document', 'system', 'message']),
  title: z.string().min(1, 'Title is required'),
  message: z.string().min(1, 'Message is required'),
  link: z.string().url().optional(),
  data: z.record(z.unknown()).optional(),
})

export type CreateNotificationInput = z.infer<typeof CreateNotificationSchema>

export const UpdateNotificationSchema = z.object({
  read: z.boolean().optional(),
})

export type UpdateNotificationInput = z.infer<typeof UpdateNotificationSchema>

// ============ VALIDATION HELPER ============

export function validateInput<T>(schema: z.ZodSchema<T>, data: unknown): T {
  const result = schema.safeParse(data)
  if (!result.success) {
    const errors = result.error.errors.map((err) => ({
      field: err.path.join('.'),
      message: err.message,
    }))
    throw new Error(JSON.stringify(errors))
  }
  return result.data
}
