# Upload Service

File upload and management service for HWY-TMS. Handles document uploads, images, PDFs, and generates thumbnails for images.

## Features

- **Multipart file upload** with type validation
- **JWT authentication** for secure access
- **File type detection** (images, documents, PDFs)
- **Automatic thumbnail generation** for images (200x200px)
- **File metadata tracking** in SurrealDB
- **User-based file management** (upload, download, delete, list)
- **Size limits** (configurable, default 50MB)
- **CORS support** for web uploads

## API Endpoints

### POST /upload
Upload a file (requires authentication)
- **Auth**: Bearer token
- **Body**: multipart/form-data with file field
- **Returns**: File metadata including ID and storage path

### GET /files/:file_id
Download a file by ID
- **Auth**: None (public access)
- **Returns**: File content with appropriate Content-Type

### GET /files/:file_id/metadata
Get file metadata
- **Auth**: None
- **Returns**: JSON metadata (filename, size, type, upload date, etc.)

### DELETE /files/:file_id
Delete a file (requires authentication, owner only)
- **Auth**: Bearer token
- **Returns**: 204 No Content on success

### GET /files/user/:user_id
List all files for a user (requires authentication)
- **Auth**: Bearer token (must match user_id)
- **Returns**: Array of file metadata

## Configuration

Environment variables:
- `DATABASE_URL` - SurrealDB connection (default: 127.0.0.1:8000)
- `JWT_SECRET` - JWT validation secret
- `UPLOAD_DIR` - File storage directory (default: ./uploads)
- `MAX_FILE_SIZE` - Maximum file size in bytes (default: 52428800 = 50MB)
- `RUST_LOG` - Logging level

## File Storage Structure

```
uploads/
├── images/          # Image files
├── documents/       # PDF and document files
├── thumbnails/      # Auto-generated thumbnails (200x200)
└── other/          # Other file types
```

## Supported File Types

- **Images**: image/* (generates thumbnails)
- **PDFs**: application/pdf
- **Documents**: application/*, text/*
- **Other**: Everything else

## Database Schema

Files are stored in the `uploads` table with:
- `id` - Unique file identifier (UUID)
- `filename` - Original filename
- `content_type` - MIME type
- `size` - File size in bytes
- `user_id` - Uploader's user ID
- `file_type` - Category (image/document/pdf/other)
- `storage_path` - Full path to file on disk
- `thumbnail_path` - Path to thumbnail (images only)
- `uploaded_at` - Upload timestamp

## Port

**8006** (internal Docker network only, exposed via Marketeer)

## Routes via Marketeer

- `POST https://api.open-hwy.com/upload` → Upload file
- `GET https://api.open-hwy.com/files/:id` → Download file
- `DELETE https://api.open-hwy.com/files/:id` → Delete file
- `GET https://api.open-hwy.com/files/:id/metadata` → Get metadata
- `GET https://api.open-hwy.com/files/user/:user_id` → List user files
