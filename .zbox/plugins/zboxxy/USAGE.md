# Installing and Running

```bash
# Build ZBOX container
docker build -t zbox:latest .

# Run ZBOX container
docker run -d \
  --name zbox-system \
  -p 80:80 \
  -p 8080:8080 \
  -v /path/to/your/models:/opt/zbox/models \
  -v /path/to/zbox/data:/opt/zbox/data \
  zbox:latest

# Create users
docker exec -it zbox-system /opt/zbox/setup_user.zsh jesse
docker exec -it zbox-system /opt/zbox/setup_user.zsh uncle_username

# Access ZBOX shells
# http://localhost/zbox/jesse
# http://localhost/zbox/uncle_username
```

**This gives you:**
1. **Custom ZBOX shell** that people log into
2. **Beautiful terminal interface** with your custom formatting
3. **User routing** through NGINX/Kubernetes  
4. **Session management** with API keys
5. **Agent orchestration** built into the shell
6. **Containerized deployment** ready for production

Is this the direction you want? The **ZBOX shell system** where users get their own custom terminal environment to interact with your models?