// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = managers/memory-manager.go

package managers

import (
	//stdlib
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/rs/zerolog/log"
	// third-party
)

// MemoryManager handles long-term conversation memory and context
type MemoryManager struct {
	mu                  sync.RWMutex
	userMemories        map[string]*UserMemoryStore
	embeddingCache      map[string][]float64
	memoryIndex         *MemoryIndex
	configManager       *ConfigManager
	maxMemoriesPerUser  int
	memoryRetention     time.Duration
	importanceThreshold float64
	shutdown            chan struct{}
}

// UserMemoryStore holds all memories for a specific user
type UserMemoryStore struct {
	UserID           string                    `json:"user_id"`
	ShortTermMemory  []*Memory                 `json:"short_term_memory"`
	LongTermMemory   []*Memory                 `json:"long_term_memory"`
	FactualKnowledge map[string]*FactualMemory `json:"factual_knowledge"`
	Preferences      map[string]*Preference    `json:"preferences"`
	Skills           map[string]*Skill         `json:"skills"`
	Relationships    map[string]*Relationship  `json:"relationships"`
	Projects         map[string]*Project       `json:"projects"`
	LastConsolidated time.Time                 `json:"last_consolidated"`
	TotalMemories    int                       `json:"total_memories"`
	CreatedAt        time.Time                 `json:"created_at"`
	UpdatedAt        time.Time                 `json:"updated_at"`
}

// Memory represents a single memory item
type Memory struct {
	ID              string                 `json:"id"`
	UserID          string                 `json:"user_id"`
	SessionID       string                 `json:"session_id,omitempty"`
	Content         string                 `json:"content"`
	Summary         string                 `json:"summary"`
	MemoryType      MemoryType             `json:"memory_type"`
	Importance      float64                `json:"importance"` // 0.0 - 1.0
	Confidence      float64                `json:"confidence"` // 0.0 - 1.0
	Freshness       float64                `json:"freshness"`  // 0.0 - 1.0 (decays over time)
	CreatedAt       time.Time              `json:"created_at"`
	LastAccessed    time.Time              `json:"last_accessed"`
	AccessCount     int                    `json:"access_count"`
	Tags            []string               `json:"tags"`
	Embedding       []float64              `json:"embedding,omitempty"`
	Source          MemorySource           `json:"source"`
	RelatedMemories []string               `json:"related_memories"`
	Metadata        map[string]interface{} `json:"metadata"`
	IsConsolidated  bool                   `json:"is_consolidated"`
}

// FactualMemory represents factual knowledge about the user
type FactualMemory struct {
	Fact        string    `json:"fact"`
	Category    string    `json:"category"`
	Confidence  float64   `json:"confidence"`
	LastUpdated time.Time `json:"last_updated"`
	Source      string    `json:"source"`
	Verified    bool      `json:"verified"`
}

// Preference represents user preferences
type Preference struct {
	Category    string    `json:"category"`
	Preference  string    `json:"preference"`
	Strength    float64   `json:"strength"` // -1.0 to 1.0 (negative = dislike)
	LastUpdated time.Time `json:"last_updated"`
	Context     string    `json:"context"`
}

// Skill represents user skills and expertise
type Skill struct {
	Name        string    `json:"name"`
	Level       string    `json:"level"` // beginner, intermediate, advanced, expert
	Confidence  float64   `json:"confidence"`
	LastUsed    time.Time `json:"last_used"`
	Improvement float64   `json:"improvement"` // Rate of improvement
	Context     []string  `json:"context"`
}

// Relationship represents relationships with people, concepts, or entities
type Relationship struct {
	Entity      string    `json:"entity"`
	Type        string    `json:"type"`     // person, concept, tool, etc.
	Strength    float64   `json:"strength"` // -1.0 to 1.0
	Description string    `json:"description"`
	LastUpdated time.Time `json:"last_updated"`
	Context     []string  `json:"context"`
}

// Project represents ongoing projects or goals
type Project struct {
	Name         string                 `json:"name"`
	Description  string                 `json:"description"`
	Status       string                 `json:"status"`
	Goals        []string               `json:"goals"`
	Progress     map[string]interface{} `json:"progress"`
	Technologies []string               `json:"technologies"`
	LastUpdated  time.Time              `json:"last_updated"`
	Priority     float64                `json:"priority"`
}

// MemoryType defines different types of memories
type MemoryType string

const (
	MemoryTypeConversation MemoryType = "conversation"
	MemoryTypeFact         MemoryType = "fact"
	MemoryTypePreference   MemoryType = "preference"
	MemoryTypeSkill        MemoryType = "skill"
	MemoryTypeGoal         MemoryType = "goal"
	MemoryTypeExperience   MemoryType = "experience"
	MemoryTypeContext      MemoryType = "context"
	MemoryTypeInsight      MemoryType = "insight"
)

// MemorySource defines where the memory came from
type MemorySource string

const (
	SourceChat          MemorySource = "chat"
	SourceCode          MemorySource = "code"
	SourceFile          MemorySource = "file"
	SourceSystem        MemorySource = "system"
	SourceInference     MemorySource = "inference"
	SourceConsolidation MemorySource = "consolidation"
)

// MemoryIndex provides fast search and retrieval of memories
type MemoryIndex struct {
	mu              sync.RWMutex
	tagIndex        map[string][]string        // tag -> memory IDs
	typeIndex       map[MemoryType][]string    // type -> memory IDs
	embeddingIndex  map[string]*EmbeddingEntry // Fast similarity search
	temporalIndex   map[string][]string        // date -> memory IDs
	importanceIndex map[float64][]string       // importance -> memory IDs
}

// EmbeddingEntry for similarity search
type EmbeddingEntry struct {
	MemoryID  string    `json:"memory_id"`
	Embedding []float64 `json:"embedding"`
	Magnitude float64   `json:"magnitude"`
}

// MemoryQuery represents a memory search query
type MemoryQuery struct {
	UserID              string        `json:"user_id"`
	Content             string        `json:"content,omitempty"`
	Tags                []string      `json:"tags,omitempty"`
	MemoryTypes         []MemoryType  `json:"memory_types,omitempty"`
	MinImportance       float64       `json:"min_importance,omitempty"`
	MaxAge              time.Duration `json:"max_age,omitempty"`
	Limit               int           `json:"limit,omitempty"`
	IncludeEmbedding    bool          `json:"include_embedding,omitempty"`
	SimilarityThreshold float64       `json:"similarity_threshold,omitempty"`
}

// MemoryResult represents search results
type MemoryResult struct {
	Memory     *Memory `json:"memory"`
	Relevance  float64 `json:"relevance"`
	Similarity float64 `json:"similarity,omitempty"`
}

// NewMemoryManager creates a new memory manager
func NewMemoryManager(configManager *ConfigManager) *MemoryManager {
	mm := &MemoryManager{
		userMemories:        make(map[string]*UserMemoryStore),
		embeddingCache:      make(map[string][]float64),
		memoryIndex:         NewMemoryIndex(),
		configManager:       configManager,
		maxMemoriesPerUser:  10000,
		memoryRetention:     365 * 24 * time.Hour, // 1 year
		importanceThreshold: 0.3,
		shutdown:            make(chan struct{}),
	}

	// Start background tasks
	go mm.runConsolidation()
	go mm.runCleanup()

	return mm
}

// StoreMemory stores a new memory for a user
func (mm *MemoryManager) StoreMemory(ctx context.Context, memory *Memory) error {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	// Get or create user memory store
	userStore := mm.getUserMemoryStore(memory.UserID)

	// Calculate importance if not set
	if memory.Importance == 0 {
		memory.Importance = mm.calculateImportance(memory)
	}

	// Calculate freshness
	memory.Freshness = 1.0

	// Generate embedding if content is meaningful
	if len(memory.Content) > 10 {
		embedding, err := mm.generateEmbedding(memory.Content)
		if err == nil {
			memory.Embedding = embedding
		}
	}

	// Set defaults
	if memory.ID == "" {
		memory.ID = mm.generateMemoryID(memory)
	}
	memory.CreatedAt = time.Now()
	memory.LastAccessed = time.Now()
	memory.AccessCount = 1

	// Determine storage location based on importance
	if memory.Importance >= mm.importanceThreshold {
		userStore.LongTermMemory = append(userStore.LongTermMemory, memory)
	} else {
		userStore.ShortTermMemory = append(userStore.ShortTermMemory, memory)
	}

	// Update indices
	mm.memoryIndex.IndexMemory(memory)

	// Store specialized memory types
	mm.storeSpecializedMemory(userStore, memory)

	userStore.TotalMemories++
	userStore.UpdatedAt = time.Now()

	log.Debug().
		Str("user_id", memory.UserID).
		Str("memory_id", memory.ID).
		Float64("importance", memory.Importance).
		Str("type", string(memory.MemoryType)).
		Msg("Stored memory")

	return nil
}

// RetrieveMemories retrieves memories based on query
func (mm *MemoryManager) RetrieveMemories(ctx context.Context, query *MemoryQuery) ([]*MemoryResult, error) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	userStore, exists := mm.userMemories[query.UserID]
	if !exists {
		return []*MemoryResult{}, nil
	}

	var results []*MemoryResult

	// Search through all memories
	allMemories := append(userStore.ShortTermMemory, userStore.LongTermMemory...)

	for _, memory := range allMemories {
		// Skip if memory doesn't match filters
		if !mm.matchesQuery(memory, query) {
			continue
		}

		result := &MemoryResult{
			Memory:    memory,
			Relevance: mm.calculateRelevance(memory, query),
		}

		// Calculate similarity if content query provided
		if query.Content != "" && len(memory.Embedding) > 0 {
			queryEmbedding, err := mm.generateEmbedding(query.Content)
			if err == nil {
				result.Similarity = mm.calculateCosineSimilarity(queryEmbedding, memory.Embedding)

				// Skip if below similarity threshold
				if query.SimilarityThreshold > 0 && result.Similarity < query.SimilarityThreshold {
					continue
				}
			}
		}

		results = append(results, result)

		// Update access statistics
		memory.LastAccessed = time.Now()
		memory.AccessCount++
	}

	// Sort by relevance and similarity
	sort.Slice(results, func(i, j int) bool {
		scoreI := results[i].Relevance + results[i].Similarity
		scoreJ := results[j].Relevance + results[j].Similarity
		return scoreI > scoreJ
	})

	// Apply limit
	if query.Limit > 0 && len(results) > query.Limit {
		results = results[:query.Limit]
	}

	return results, nil
}

func (mm *MemoryManager) GetUserMemories(userID string) ([]*Memory, error) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()
	store, exists := mm.userMemories[userID]
	if !exists {
		return nil, fmt.Errorf("user not found: %s", userID)
	}
	all := append([]*Memory{}, store.ShortTermMemory...)
	all = append(all, store.LongTermMemory...)
	return all, nil
}

func (mm *MemoryManager) GetAllUsers() []string {
	mm.mu.RLock()
	defer mm.mu.RUnlock()
	users := make([]string, 0, len(mm.userMemories))
	for userID := range mm.userMemories {
		users = append(users, userID)
	}
	return users
}

// GetUserProfile builds a comprehensive user profile from memories
func (mm *MemoryManager) GetUserProfile(userID string) (*UserProfile, error) {
	mm.mu.RLock()
	defer mm.mu.RUnlock()

	userStore, exists := mm.userMemories[userID]
	if !exists {
		return nil, fmt.Errorf("user not found: %s", userID)
	}

	profile := &UserProfile{
		UserID:             userID,
		Name:               mm.extractName(userStore),
		PreferredModels:    mm.extractPreferredModels(userStore),
		CommunicationStyle: mm.extractCommunicationStyle(userStore),
		ExpertiseAreas:     mm.extractExpertiseAreas(userStore),
		LearningGoals:      mm.extractLearningGoals(userStore),
		Preferences:        mm.convertPreferences(userStore.Preferences),
		Timezone:           mm.extractTimezone(userStore),
		Language:           mm.extractLanguage(userStore),
	}

	return profile, nil
}

// ConsolidateMemories consolidates short-term memories into long-term
func (mm *MemoryManager) ConsolidateMemories(ctx context.Context, userID string) error {
	mm.mu.Lock()
	defer mm.mu.Unlock()

	userStore, exists := mm.userMemories[userID]
	if !exists {
		return fmt.Errorf("user not found: %s", userID)
	}

	// Find related short-term memories
	clusters := mm.clusterRelatedMemories(userStore.ShortTermMemory)

	for _, cluster := range clusters {
		if len(cluster) >= 3 { // Need at least 3 related memories to consolidate
			consolidated := mm.consolidateCluster(cluster)
			if consolidated != nil {
				// Add to long-term memory
				userStore.LongTermMemory = append(userStore.LongTermMemory, consolidated)

				// Mark original memories as consolidated
				for _, memory := range cluster {
					memory.IsConsolidated = true
				}
			}
		}
	}

	// Clean up consolidated short-term memories
	newShortTerm := make([]*Memory, 0)
	for _, memory := range userStore.ShortTermMemory {
		if !memory.IsConsolidated {
			newShortTerm = append(newShortTerm, memory)
		}
	}
	userStore.ShortTermMemory = newShortTerm

	userStore.LastConsolidated = time.Now()

	log.Info().
		Str("user_id", userID).
		Int("clusters", len(clusters)).
		Msg("Consolidated memories")

	return nil
}

// Helper functions

func (mm *MemoryManager) getUserMemoryStore(userID string) *UserMemoryStore {
	store, exists := mm.userMemories[userID]
	if !exists {
		store = &UserMemoryStore{
			UserID:           userID,
			ShortTermMemory:  make([]*Memory, 0),
			LongTermMemory:   make([]*Memory, 0),
			FactualKnowledge: make(map[string]*FactualMemory),
			Preferences:      make(map[string]*Preference),
			Skills:           make(map[string]*Skill),
			Relationships:    make(map[string]*Relationship),
			Projects:         make(map[string]*Project),
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		}
		mm.userMemories[userID] = store
	}
	return store
}

func (mm *MemoryManager) calculateImportance(memory *Memory) float64 {
	importance := 0.0

	// Base importance by type
	switch memory.MemoryType {
	case MemoryTypeFact:
		importance += 0.7
	case MemoryTypePreference:
		importance += 0.6
	case MemoryTypeSkill:
		importance += 0.8
	case MemoryTypeGoal:
		importance += 0.9
	case MemoryTypeInsight:
		importance += 0.8
	default:
		importance += 0.4
	}

	// Boost for keywords that indicate importance
	importantKeywords := []string{"important", "remember", "always", "never", "love", "hate", "goal", "project"}
	content := strings.ToLower(memory.Content)
	for _, keyword := range importantKeywords {
		if strings.Contains(content, keyword) {
			importance += 0.1
		}
	}

	// Boost for questions (often indicate learning)
	if strings.Contains(content, "?") {
		importance += 0.2
	}

	// Boost for longer content (more detailed)
	if len(memory.Content) > 100 {
		importance += 0.1
	}

	// Cap at 1.0
	if importance > 1.0 {
		importance = 1.0
	}

	return importance
}

func (mm *MemoryManager) generateEmbedding(content string) ([]float64, error) {
	// Check cache first
	hash := mm.hashContent(content)
	if embedding, exists := mm.embeddingCache[hash]; exists {
		return embedding, nil
	}

	// Simple embedding generation (in practice, you'd use a real embedding model)
	// This creates a basic word frequency vector
	embedding := mm.createSimpleEmbedding(content)

	// Cache the result
	mm.embeddingCache[hash] = embedding

	return embedding, nil
}

func (mm *MemoryManager) createSimpleEmbedding(content string) []float64 {
	// Simple word frequency embedding (300 dimensions)
	embedding := make([]float64, 300)
	words := strings.Fields(strings.ToLower(content))

	for i, word := range words {
		if i >= 300 {
			break
		}
		// Simple hash-based embedding
		hash := mm.simpleHash(word)
		embedding[hash%300] += 1.0
	}

	// Normalize
	magnitude := 0.0
	for _, val := range embedding {
		magnitude += val * val
	}
	magnitude = math.Sqrt(magnitude)

	if magnitude > 0 {
		for i := range embedding {
			embedding[i] /= magnitude
		}
	}

	return embedding
}

func (mm *MemoryManager) calculateCosineSimilarity(a, b []float64) float64 {
	if len(a) != len(b) {
		return 0
	}

	dotProduct := 0.0
	magnitudeA := 0.0
	magnitudeB := 0.0

	for i := 0; i < len(a); i++ {
		dotProduct += a[i] * b[i]
		magnitudeA += a[i] * a[i]
		magnitudeB += b[i] * b[i]
	}

	magnitudeA = math.Sqrt(magnitudeA)
	magnitudeB = math.Sqrt(magnitudeB)

	if magnitudeA == 0 || magnitudeB == 0 {
		return 0
	}

	return dotProduct / (magnitudeA * magnitudeB)
}

func (mm *MemoryManager) generateMemoryID(memory *Memory) string {
	data := fmt.Sprintf("%s_%s_%s_%d", memory.UserID, memory.Content, string(memory.MemoryType), time.Now().UnixNano())
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:8])
}

func (mm *MemoryManager) hashContent(content string) string {
	hash := sha256.Sum256([]byte(content))
	return hex.EncodeToString(hash[:])
}

func (mm *MemoryManager) simpleHash(s string) int {
	hash := 0
	for _, char := range s {
		hash = hash*31 + int(char)
	}
	if hash < 0 {
		hash = -hash
	}
	return hash
}

func (mm *MemoryManager) matchesQuery(memory *Memory, query *MemoryQuery) bool {
	// Check memory types
	if len(query.MemoryTypes) > 0 {
		found := false
		for _, memType := range query.MemoryTypes {
			if memory.MemoryType == memType {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Check minimum importance
	if query.MinImportance > 0 && memory.Importance < query.MinImportance {
		return false
	}

	// Check max age
	if query.MaxAge > 0 && time.Since(memory.CreatedAt) > query.MaxAge {
		return false
	}

	// Check tags
	if len(query.Tags) > 0 {
		found := false
		for _, queryTag := range query.Tags {
			for _, memoryTag := range memory.Tags {
				if strings.EqualFold(queryTag, memoryTag) {
					found = true
					break
				}
			}
			if found {
				break
			}
		}
		if !found {
			return false
		}
	}

	return true
}

func (mm *MemoryManager) calculateRelevance(memory *Memory, query *MemoryQuery) float64 {
	relevance := memory.Importance

	// Boost recent memories
	age := time.Since(memory.CreatedAt)
	if age < 24*time.Hour {
		relevance += 0.2
	} else if age < 7*24*time.Hour {
		relevance += 0.1
	}

	// Boost frequently accessed memories
	if memory.AccessCount > 5 {
		relevance += 0.1
	}

	// Boost by freshness (decays over time)
	relevance += memory.Freshness * 0.1

	return math.Min(relevance, 1.0)
}

// Background tasks

func (mm *MemoryManager) runConsolidation() {
	ticker := time.NewTicker(24 * time.Hour) // Daily consolidation
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			mm.performDailyConsolidation()
		case <-mm.shutdown:
			return
		}
	}
}

func (mm *MemoryManager) runCleanup() {
	ticker := time.NewTicker(7 * 24 * time.Hour) // Weekly cleanup
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			mm.performWeeklyCleanup()
		case <-mm.shutdown:
			return
		}
	}
}

func (mm *MemoryManager) performDailyConsolidation() {
	mm.mu.RLock()
	userIDs := make([]string, 0, len(mm.userMemories))
	for userID := range mm.userMemories {
		userIDs = append(userIDs, userID)
	}
	mm.mu.RUnlock()

	for _, userID := range userIDs {
		if err := mm.ConsolidateMemories(context.Background(), userID); err != nil {
			log.Error().Err(err).Str("user_id", userID).Msg("Failed to consolidate memories")
		}
	}
}

func (mm *MemoryManager) performWeeklyCleanup() {
	// Update freshness scores and remove very old, low-importance memories
	mm.mu.Lock()
	defer mm.mu.Unlock()

	for _, userStore := range mm.userMemories {
		// Update freshness scores
		for _, memory := range userStore.ShortTermMemory {
			memory.Freshness = mm.calculateFreshness(memory)
		}

		// Remove old, unimportant short-term memories
		newShortTerm := make([]*Memory, 0)
		for _, memory := range userStore.ShortTermMemory {
			if memory.Importance > 0.2 || time.Since(memory.CreatedAt) < 30*24*time.Hour {
				newShortTerm = append(newShortTerm, memory)
			}
		}
		userStore.ShortTermMemory = newShortTerm
	}
}

func (mm *MemoryManager) calculateFreshness(memory *Memory) float64 {
	age := time.Since(memory.CreatedAt)
	daysSinceCreated := age.Hours() / 24

	// Exponential decay
	freshness := math.Exp(-daysSinceCreated / 30.0) // 30-day half-life

	// Boost if recently accessed
	if time.Since(memory.LastAccessed) < 24*time.Hour {
		freshness += 0.2
	}

	return math.Min(freshness, 1.0)
}

// Placeholder implementations for profile extraction
func (mm *MemoryManager) extractName(store *UserMemoryStore) string { return "User" }
func (mm *MemoryManager) extractPreferredModels(store *UserMemoryStore) []string {
	return []string{"llama3.2"}
}
func (mm *MemoryManager) extractCommunicationStyle(store *UserMemoryStore) string { return "helpful" }
func (mm *MemoryManager) extractExpertiseAreas(store *UserMemoryStore) []string   { return []string{} }
func (mm *MemoryManager) extractLearningGoals(store *UserMemoryStore) []string    { return []string{} }
func (mm *MemoryManager) extractTimezone(store *UserMemoryStore) string           { return "UTC" }
func (mm *MemoryManager) extractLanguage(store *UserMemoryStore) string           { return "en" }

func (mm *MemoryManager) convertPreferences(prefs map[string]*Preference) map[string]string {
	result := make(map[string]string)
	for k, v := range prefs {
		result[k] = v.Preference
	}
	return result
}

func (mm *MemoryManager) storeSpecializedMemory(store *UserMemoryStore, memory *Memory) {
	// Store in specialized collections based on type
	switch memory.MemoryType {
	case MemoryTypeFact:
		if fact := mm.extractFact(memory); fact != nil {
			store.FactualKnowledge[fact.Category] = fact
		}
	case MemoryTypePreference:
		if pref := mm.extractPreference(memory); pref != nil {
			store.Preferences[pref.Category] = pref
		}
	case MemoryTypeSkill:
		if skill := mm.extractSkill(memory); skill != nil {
			store.Skills[skill.Name] = skill
		}
	}
}

// Placeholder extractors for specialized memory types
func (mm *MemoryManager) extractFact(memory *Memory) *FactualMemory             { return nil }
func (mm *MemoryManager) extractPreference(memory *Memory) *Preference          { return nil }
func (mm *MemoryManager) extractSkill(memory *Memory) *Skill                    { return nil }
func (mm *MemoryManager) clusterRelatedMemories(memories []*Memory) [][]*Memory { return nil }
func (mm *MemoryManager) consolidateCluster(cluster []*Memory) *Memory          { return nil }

// Memory Index implementation
func NewMemoryIndex() *MemoryIndex {
	return &MemoryIndex{
		tagIndex:        make(map[string][]string),
		typeIndex:       make(map[MemoryType][]string),
		embeddingIndex:  make(map[string]*EmbeddingEntry),
		temporalIndex:   make(map[string][]string),
		importanceIndex: make(map[float64][]string),
	}
}

func (mi *MemoryIndex) IndexMemory(memory *Memory) {
	mi.mu.Lock()
	defer mi.mu.Unlock()

	// Index by tags
	for _, tag := range memory.Tags {
		mi.tagIndex[tag] = append(mi.tagIndex[tag], memory.ID)
	}

	// Index by type
	mi.typeIndex[memory.MemoryType] = append(mi.typeIndex[memory.MemoryType], memory.ID)

	// Index by date
	dateKey := memory.CreatedAt.Format("2006-01-02")
	mi.temporalIndex[dateKey] = append(mi.temporalIndex[dateKey], memory.ID)

	// Index by importance (rounded to 1 decimal place)
	importanceKey := math.Round(memory.Importance*10) / 10
	mi.importanceIndex[importanceKey] = append(mi.importanceIndex[importanceKey], memory.ID)

	// Index embedding
	if len(memory.Embedding) > 0 {
		magnitude := 0.0
		for _, val := range memory.Embedding {
			magnitude += val * val
		}
		magnitude = math.Sqrt(magnitude)

		mi.embeddingIndex[memory.ID] = &EmbeddingEntry{
			MemoryID:  memory.ID,
			Embedding: memory.Embedding,
			Magnitude: magnitude,
		}
	}
}

// Shutdown gracefully shuts down the memory manager
func (mm *MemoryManager) Shutdown(ctx context.Context) error {
	log.Info().Msg("Shutting down memory manager")
	close(mm.shutdown)
	log.Info().Msg("Memory manager shutdown complete")
	return nil
}
