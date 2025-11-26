// internal/domain/entities/role.go
package entities

// Role represents user roles in the system
type Role string

const (
	RoleAdmin     Role = "admin"
	RoleUser      Role = "user"
	RoleModerator Role = "moderator"
	RoleGuest     Role = "guest"
)

// Permission represents system permissions
type Permission string

const (
	PermissionUserRead   Permission = "user:read"
	PermissionUserWrite  Permission = "user:write"
	PermissionUserDelete Permission = "user:delete"
	PermissionAdminRead  Permission = "admin:read"
	PermissionAdminWrite Permission = "admin:write"
)

// rolePermissions maps roles to their permissions
var rolePermissions = map[Role][]Permission{
	RoleAdmin: {
		PermissionUserRead, PermissionUserWrite, PermissionUserDelete,
		PermissionAdminRead, PermissionAdminWrite,
	},
	RoleModerator: {
		PermissionUserRead, PermissionUserWrite,
	},
	RoleUser: {
		PermissionUserRead,
	},
	RoleGuest: {},
}

// HasPermission checks if the role has the specified permission
func (r Role) HasPermission(permission Permission) bool {
	permissions, exists := rolePermissions[r]
	if !exists {
		return false
	}

	for _, p := range permissions {
		if p == permission {
			return true
		}
	}
	return false
}

// GetPermissions returns all permissions for the role
func (r Role) GetPermissions() []Permission {
	return rolePermissions[r]
}
