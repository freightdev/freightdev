# Budibase Docker Compose Setup

This Docker Compose setup will deploy a complete Budibase instance with all required services.

## Services Included

- **app-service**: Main Budibase application
- **worker-service**: Background job processor
- **proxy-service**: Nginx reverse proxy
- **couchdb-service**: Database for storing app data
- **minio-service**: Object storage for files and attachments
- **redis-service**: Cache and session storage

## Prerequisites

- Docker installed (version 20.10 or higher)
- Docker Compose installed (version 2.0 or higher)

## Quick Start

1. **Copy the environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file** and update all passwords and secrets:
   - Change all `change_me_*` values to strong, unique passwords
   - You can generate secure random strings with:
     ```bash
     openssl rand -hex 32
     ```

3. **Start Budibase**:
   ```bash
   docker-compose up -d
   ```

4. **Access Budibase**:
   - Open your browser and go to: `http://localhost:10000`
   - Or use your server's IP: `http://YOUR_SERVER_IP:10000`

5. **Create your first admin user**:
   - Follow the on-screen setup wizard
   - Or use the credentials from `BB_ADMIN_USER_EMAIL` and `BB_ADMIN_USER_PASSWORD` in your `.env` file

## Managing the Stack

### View logs
```bash
docker-compose logs -f
```

### Stop Budibase
```bash
docker-compose down
```

### Stop and remove all data
```bash
docker-compose down -v
```

### Update Budibase
```bash
docker-compose pull
docker-compose up -d
```

## Customization

### Change the Port

Edit the `MAIN_PORT` variable in your `.env` file:
```
MAIN_PORT=8080
```

### Backup Data

All data is stored in Docker volumes:
- `couchdb_data`: Database data
- `minio_data`: File uploads
- `redis_data`: Cache data

To backup:
```bash
docker run --rm -v budibase_couchdb_data:/data -v $(pwd):/backup ubuntu tar czf /backup/couchdb-backup.tar.gz /data
docker run --rm -v budibase_minio_data:/data -v $(pwd):/backup ubuntu tar czf /backup/minio-backup.tar.gz /data
```

## Troubleshooting

### Container won't start
- Check logs: `docker-compose logs [service-name]`
- Ensure all environment variables are set correctly
- Make sure ports aren't already in use

### Can't connect to Budibase
- Verify the proxy service is running: `docker-compose ps`
- Check if port 10000 is accessible (or your custom port)
- Check firewall rules if accessing remotely

### Reset everything
```bash
docker-compose down -v
docker-compose up -d
```

## Security Notes

- **Change all default passwords** in the `.env` file
- Use strong, unique passwords for all services
- Consider using a reverse proxy with SSL/TLS for production
- Keep your Budibase installation updated regularly

## Support

For more information, visit the official Budibase documentation:
https://docs.budibase.com/
