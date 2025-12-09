// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/disk-manager.go

package managers

import (
	// stdlib
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	// third-party
	"github.com/rs/zerolog/log"
)


// DiskManager handles persistent storage and file operations
type DiskManager struct {
	mu              sync.RWMutex
	configManager   *ConfigManager
	memoryManager   *MemoryManager
	sessionManager  *SessionManager
	conversationMgr *ConversationManager
	dataDir         string        // Base directory for storage
	backupDir       string        // Directory for backups
	maxDiskUsage    int64         // Max disk usage in bytes
	retentionDays   int           // Days to retain data
	backupInterval  time.Duration // Time between backups
	shutdown        chan struct{}
	backupTicker    *time.Ticker
}

// StorageConfig holds disk-related configuration
type StorageConfig struct {
	DataDir        string `yaml:"data_dir"`
	BackupDir      string `yaml:"backup_dir"`
	MaxDiskUsage   int64  `yaml:"max_disk_usage"`  // In bytes
	RetentionDays  int    `yaml:"retention_days"`  // Days to keep data
	BackupInterval int    `yaml:"backup_interval"` // Hours between backups
}

// FileMetadata holds metadata for stored files
type FileMetadata struct {
	Path       string                 `json:"path"`
	Size       int64                  `json:"size"`
	CreatedAt  time.Time              `json:"created_at"`
	ModifiedAt time.Time              `json:"modified_at"`
	Type       string                 `json:"type"` // e.g., "memory", "session", "conversation"
	OwnerID    string                 `json:"owner_id"`
	Metadata   map[string]interface{} `json:"metadata"`
}

// NewDiskManager creates a new disk manager
func NewDiskManager(cfgMgr *ConfigManager, memMgr *MemoryManager, sessMgr *SessionManager, convMgr *ConversationManager) (*DiskManager, error) {
	storageConfig := &StorageConfig{
		DataDir:        "../data",
		BackupDir:      "../backups",
		MaxDiskUsage:   10 * 1024 * 1024 * 1024,
		RetentionDays:  30,
		BackupInterval: 24,
	}

	if err := cfgMgr.LoadConfig("configs/storage.yaml", storageConfig); err != nil {
		log.Warn().Err(err).Msg("Failed to load storage config, using defaults")
	}

	dm := &DiskManager{
		configManager:   cfgMgr,
		memoryManager:   memMgr,
		sessionManager:  sessMgr,
		conversationMgr: convMgr,
		dataDir:         storageConfig.DataDir,
		backupDir:       storageConfig.BackupDir,
		maxDiskUsage:    storageConfig.MaxDiskUsage,
		retentionDays:   storageConfig.RetentionDays,
		backupInterval:  time.Duration(storageConfig.BackupInterval) * time.Hour,
		shutdown:        make(chan struct{}),
		backupTicker:    time.NewTicker(time.Duration(storageConfig.BackupInterval) * time.Hour),
	}

	if err := dm.ensureDirectories(); err != nil {
		return nil, fmt.Errorf("failed to initialize directories: %w", err)
	}

	go dm.runBackgroundTasks()

	return dm, nil
}

// ensureDirectories creates necessary directories
func (dm *DiskManager) ensureDirectories() error {
	dirs := []string{
		dm.dataDir,
		filepath.Join(dm.dataDir, "memories"),
		filepath.Join(dm.dataDir, "sessions"),
		filepath.Join(dm.dataDir, "conversations"),
		dm.backupDir,
	}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}
	return nil
}

// SaveMemory persists a memory to disk

func (dm *DiskManager) SaveMemory(memory *Memory) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	if err := dm.checkDiskUsage(); err != nil {
		return err
	}
	path := filepath.Join(dm.dataDir, "memories", memory.UserID, fmt.Sprintf("%s.json", memory.ID))
	data, err := json.MarshalIndent(memory, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal memory: %w", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("write memory: %w", err)
	}
	log.Info().Str("memory_id", memory.ID).Str("user_id", memory.UserID).Str("path", path).Msg("Saved memory")
	return nil
}

// LoadMemory retrieves a memory from disk
func (dm *DiskManager) LoadMemory(userID, memoryID string) (*Memory, error) {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	path := filepath.Join(dm.dataDir, "memories", userID, fmt.Sprintf("%s.json", memoryID))
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read memory: %w", err)
	}
	var memory Memory
	if err := json.Unmarshal(data, &memory); err != nil {
		return nil, fmt.Errorf("unmarshal memory: %w", err)
	}
	return &memory, nil
}

// SaveSession persists a session to disk
func (dm *DiskManager) SaveSession(session *Session) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	if err := dm.checkDiskUsage(); err != nil {
		return err
	}
	path := filepath.Join(dm.dataDir, "sessions", fmt.Sprintf("%s.json", session.ID))
	data, err := json.MarshalIndent(session, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal session: %w", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("write session: %w", err)
	}
	log.Info().Str("session_id", session.ID).Str("user_id", session.UserID).Str("path", path).Msg("Saved session")
	return nil
}

// LoadSession retrieves a session from disk
func (dm *DiskManager) LoadSession(sessionID string) (*Session, error) {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	path := filepath.Join(dm.dataDir, "sessions", fmt.Sprintf("%s.json", sessionID))
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read session: %w", err)
	}
	var session Session
	if err := json.Unmarshal(data, &session); err != nil {
		return nil, fmt.Errorf("unmarshal session: %w", err)
	}
	return &session, nil
}

// SaveConversation persists a conversation to disk
func (dm *DiskManager) SaveConversation(conversation *Conversation) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	if err := dm.checkDiskUsage(); err != nil {
		return err
	}
	path := filepath.Join(dm.dataDir, "conversations", fmt.Sprintf("%s.json", conversation.ID))
	data, err := json.MarshalIndent(conversation, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal conversation: %w", err)
	}
	if err := os.WriteFile(path, data, 0644); err != nil {
		return fmt.Errorf("write conversation: %w", err)
	}
	log.Info().Str("conversation_id", conversation.ID).Str("user_id", conversation.UserID).Str("path", path).Msg("Saved conversation")
	return nil
}

// LoadConversation retrieves a conversation from disk
func (dm *DiskManager) LoadConversation(conversationID string) (*Conversation, error) {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	path := filepath.Join(dm.dataDir, "conversations", fmt.Sprintf("%s.json", conversationID))
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read conversation: %w", err)
	}
	var conv Conversation
	if err := json.Unmarshal(data, &conv); err != nil {
		return nil, fmt.Errorf("unmarshal conversation: %w", err)
	}
	return &conv, nil
}

// CreateBackup creates a backup of specified data
func (dm *DiskManager) CreateBackup(dataType, userID string) error {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	backupPath := filepath.Join(dm.backupDir, fmt.Sprintf("%s_%s_%s.bak", dataType, userID, time.Now().Format("20060102_150405")))
	switch dataType {
	case "memory":
		return dm.backupMemories(userID, backupPath)
	case "session":
		return dm.backupSessions(userID, backupPath)
	case "conversation":
		return dm.backupConversations(userID, backupPath)
	default:
		return fmt.Errorf("unsupported backup type: %s", dataType)
	}
}

// backupMemories backs up user memories
func (dm *DiskManager) backupMemories(userID, backupPath string) error {
	memories, err := dm.memoryManager.GetUserMemories(userID)
	if err != nil {
		return err
	}
	data, err := json.MarshalIndent(memories, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(backupPath, data, 0644); err != nil {
		return err
	}
	log.Info().Str("user_id", userID).Str("backup", backupPath).Msg("Memory backup created")
	return nil
}

// backupSessions backs up user sessions
func (dm *DiskManager) backupSessions(userID, backupPath string) error {
	sessions := dm.sessionManager.GetUserSessions(userID)
	data, _ := json.MarshalIndent(sessions, "", "  ")
	os.WriteFile(backupPath, data, 0644)
	log.Info().Str("user_id", userID).Str("backup", backupPath).Msg("Session backup created")
	return nil
}

// backupConversations backs up user conversations
func (dm *DiskManager) backupConversations(userID, backupPath string) error {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	convs := dm.conversationMgr.conversationsByUser[userID]
	data := make([]*Conversation, 0, len(convs))
	for _, c := range convs {
		data = append(data, c)
	}
	jsonData, _ := json.MarshalIndent(data, "", "  ")
	os.WriteFile(backupPath, jsonData, 0644)
	log.Info().Str("user_id", userID).Str("backup", backupPath).Msg("Conversation backup created")
	return nil
}

// checkDiskUsage ensures disk usage stays within limits
func (dm *DiskManager) checkDiskUsage() error {
	var total int64
	filepath.Walk(dm.dataDir, func(path string, info os.FileInfo, err error) error {
		if info != nil && !info.IsDir() {
			total += info.Size()
		}
		return nil
	})
	if total > dm.maxDiskUsage {
		return fmt.Errorf("disk usage exceeded: %d > %d", total, dm.maxDiskUsage)
	}
	return nil
}

// cleanupOldData removes data older than retention period
func (dm *DiskManager) cleanupOldData() {
	dm.mu.Lock()
	defer dm.mu.Unlock()
	cutoff := time.Now().AddDate(0, 0, -dm.retentionDays)
	dirs := []string{"memories", "sessions", "conversations"}
	for _, d := range dirs {
		dir := filepath.Join(dm.dataDir, d)
		filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() && info.ModTime().Before(cutoff) {
				os.Remove(path)
			}
			return nil
		})
	}
}

// runBackgroundTasks handles periodic cleanup and backups
func (dm *DiskManager) runBackgroundTasks() {
	for {
		select {
		case <-dm.backupTicker.C:
			featureCfg, err := dm.configManager.GetFeatureConfig()
			if err == nil && featureCfg.EnableAutoBackup {
				for uidInt := range dm.memoryManager.GetAllUsers() {
					uid := fmt.Sprintf("%d", uidInt)
					for _, dt := range []string{"memory", "session", "conversation"} {
						dm.CreateBackup(dt, uid)
					}
				}
			}
			dm.cleanupOldData()
		case <-dm.shutdown:
			dm.backupTicker.Stop()
			return
		}
	}
}

// getMemoryFilePath generates file path for memory storage
func (dm *DiskManager) getMemoryFilePath(userID, memoryID string) string {
	return filepath.Join(dm.dataDir, "memories", userID, fmt.Sprintf("%s.json", memoryID))
}

// getSessionFilePath generates file path for session storage
func (dm *DiskManager) getSessionFilePath(sessionID string) string {
	return filepath.Join(dm.dataDir, "sessions", fmt.Sprintf("%s.json", sessionID))
}

// getConversationFilePath generates file path for conversation storage
func (dm *DiskManager) getConversationFilePath(conversationID string) string {
	return filepath.Join(dm.dataDir, "conversations", fmt.Sprintf("%s.json", conversationID))
}

// Shutdown gracefully shuts down the disk manager
func (dm *DiskManager) Shutdown() {
	close(dm.shutdown)
	for uidInt := range dm.memoryManager.GetAllUsers() {
		uid := fmt.Sprintf("%d", uidInt)
		for _, dt := range []string{"memory", "session", "conversation"} {
			dm.CreateBackup(dt, uid)
		}
	}
	log.Info().Msg("Disk manager shutdown complete")
}
