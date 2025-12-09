// internal/domain/entities/profile.go (same file for brevity)

type Profile struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	UserID      uuid.UUID  `json:"user_id" db:"user_id"`
	FirstName   string     `json:"first_name" db:"first_name"`
	LastName    string     `json:"last_name" db:"last_name"`
	Avatar      *string    `json:"avatar,omitempty" db:"avatar"`
	Bio         *string    `json:"bio,omitempty" db:"bio"`
	Location    *string    `json:"location,omitempty" db:"location"`
	Website     *string    `json:"website,omitempty" db:"website"`
	DateOfBirth *time.Time `json:"date_of_birth,omitempty" db:"date_of_birth"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
}

func NewProfile(userID uuid.UUID, firstName, lastName string) *Profile {
	return &Profile{
		ID:        uuid.New(),
		UserID:    userID,
		FirstName: firstName,
		LastName:  lastName,
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}
}

func (p *Profile) UpdateBasicInfo(firstName, lastName string) {
	p.FirstName = firstName
	p.LastName = lastName
	p.UpdatedAt = time.Now().UTC()
}

func (p *Profile) UpdateBio(bio string) {
	p.Bio = &bio
	p.UpdatedAt = time.Now().UTC()
}

func (p *Profile) GetFullName() string {
	return p.FirstName + " " + p.LastName
}
