# Scaffold CLI - Version 1.0.0

## Installation & Usage:

```bash
# Make the script executable
chmod +x scaffold

# Test with dry run first
./scaffold simple.tree ./output --dry

# Create the structure
./scaffold simple.tree ./output

# Handle suspicious patterns (will prompt for confirmation)
./scaffold malicious.tree ./test-danger

# Force creation without prompts
./scaffold enterprise.md ./my-enterprise-app --force

# Debug mode for troubleshooting
./scaffold mixed.txt ./mixed-output --debug --dry
```

## **How It Works?**

### **Step 1: Mark Key / Mark Value**

* Find all **`/`** then mark as key.
>  EX: Key= `│ ├── data/`, 
>      Key= `├── conversations/`
>      Key= `│   │   │   │   │   │   ├── level7/`
>      Key
* Find

* Find all **`.`** then mark as file.
> EX: ` └── root.txt`= **root.txt**, `│   │   └── _meta.schema.yaml`= **_meta.schema.yaml**, `└── full_backup_2025-01-14.tar.gz`= **full_backup_2025-01-14.tar.gz**

### **Step 2:**

* 




