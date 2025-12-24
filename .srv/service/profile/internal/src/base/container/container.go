/ internal/infrastructure/container/container.go
package container

import (
	"user_service/internal/application/handlers/http"
	"user_service/internal/application/services"
	"user_service/internal/config"
	"user_service/internal/domain/services"
	"user_service/internal/infrastructure/database/postgres"
	"user_service/internal/infrastructure/redis"
	"user_service/internal/shared/logger"
)

type Container struct {
	Config *config.Config
	Logger logger.Logger

	// Infrastructure
	Database    *postgres.Database
	RedisClient *redis.Client

	// Repositories
	UserRepository    repositories.UserRepository
	ProfileRepository repositories.ProfileRepository

	// Domain Services
	UserDomainService services.UserDomainService

	// Application Services
	UserApplicationService services.UserApplicationService

	// HTTP Handlers
	UserHandler   *http.UserHandler
	HealthHandler *http.HealthHandler
}

func NewContainer(cfg *config.Config) (*Container, error) {
	container := &Container{
		Config: cfg,
	}

	if err := container.initLogger(); err != nil {
		return nil, err
	}

	if err := container.initInfrastructure(); err != nil {
		return nil, err
	}

	if err := container.initRepositories(); err != nil {
		return nil, err
	}

	if err := container.initDomainServices(); err != nil {
		return nil, err
	}

	if err := container.initApplicationServices(); err != nil {
		return nil, err
	}

	if err := container.initHandlers(); err != nil {
		return nil, err
	}

	return container, nil
}

func (c *Container) initLogger() error {
	logger, err := logger.NewLogger(c.Config.Logging)
	if err != nil {
		return err
	}

	c.Logger = logger
	return nil
}

func (c *Container) initInfrastructure() error {
	// Initialize database
	db, err := postgres.NewConnection(c.Config.Database, c.Logger)
	if err != nil {
		return err
	}
	c.Database = db

	// Initialize Redis
	redisClient, err := redis.NewClient(c.Config.Redis, c.Logger)
	if err != nil {
		return err
	}
	c.RedisClient = redisClient

	return nil
}

func (c *Container) initRepositories() error {
	c.UserRepository = postgres.NewUserRepository(c.Database)
	c.ProfileRepository = postgres.NewProfileRepository(c.Database)

	return nil
}

func (c *Container) initDomainServices() error {
	c.UserDomainService = services.NewUserDomainService(
		c.UserRepository,
		c.ProfileRepository,
	)

	return nil
}

func (c *Container) initApplicationServices() error {
	c.UserApplicationService = services.NewUserApplicationService(
		c.UserRepository,
		c.ProfileRepository,
		c.UserDomainService,
		c.Logger,
	)

	return nil
}

func (c *Container) initHandlers() error {
	c.UserHandler = http.NewUserHandler(c.UserApplicationService, c.Logger)
	c.HealthHandler = http.NewHealthHandler(c.Logger)

	return nil
}

func (c *Container) Close() error {
	c.Logger.Info("Shutting down container")

	if c.RedisClient != nil {
		if err := c.RedisClient.Close(); err != nil {
			c.Logger.Error("Failed to close Redis connection", zap.Error(err))
		}
	}

	if c.Database != nil {
		if err := c.Database.Close(); err != nil {
			c.Logger.Error("Failed to close database connection", zap.Error(err))
		}
	}

	if err := c.Logger.Sync(); err != nil {
		// Can't log this error since we're closing the logger
		return err
	}

	return nil
}
