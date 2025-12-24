// internal/infrastructure/database/migrations/migrator.go
package migrations

import (
	"database/sql"
	"fmt"

	"github.com/rubenv/sql-migrate"
	"go.uber.org/zap"

	"user_service/internal/shared/logger"
)

type Migrator struct {
	db     *sql.DB
	logger logger.Logger
}

func NewMigrator(db *sql.DB, logger logger.Logger) *Migrator {
	return &Migrator{
		db:     db,
		logger: logger,
	}
}

func (m *Migrator) Up() error {
	migrations := &migrate.FileMigrationSource{
		Dir: "internal/infrastructure/database/migrations",
	}

	n, err := migrate.Exec(m.db, "postgres", migrations, migrate.Up)
	if err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	m.logger.Info("Migrations applied successfully", zap.Int("count", n))
	return nil
}

func (m *Migrator) Down() error {
	migrations := &migrate.FileMigrationSource{
		Dir: "internal/infrastructure/database/migrations",
	}

	n, err := migrate.Exec(m.db, "postgres", migrations, migrate.Down)
	if err != nil {
		return fmt.Errorf("failed to rollback migrations: %w", err)
	}

	m.logger.Info("Migrations rolled back successfully", zap.Int("count", n))
	return nil
}

func (m *Migrator) Status() ([]*migrate.MigrationRecord, error) {
	migrations := &migrate.FileMigrationSource{
		Dir: "internal/infrastructure/database/migrations",
	}

	records, err := migrate.GetMigrationRecords(m.db, "postgres")
	if err != nil {
		return nil, fmt.Errorf("failed to get migration status: %w", err)
	}

	return records, nil
}
