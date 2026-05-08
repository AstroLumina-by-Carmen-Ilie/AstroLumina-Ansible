# AstroLumina-Ansible

Ansible automation project for managing the AstroLumina RKE2 Kubernetes cluster infrastructure.

## Project Structure

```
AstroLumina-Ansible/
├── ansible.cfg           # Ansible configuration
├── inventory/            # Inventory files
│   └── inventory        # Host definitions
├── playbooks/            # Ansible playbooks
├── roles/                # Ansible roles (reusable)
├── group_vars/           # Group variables
├── host_vars/            # Host-specific variables
└── README.md            # This file
```

## Requirements

- **Ansible**: version 2.14+
- **Python**: 3.10+
- **SSH Access**: Key-based authentication to target hosts

## Inventory

The inventory defines the RKE2 cluster nodes:

| Host | Role | IP Address |
|------|------|-------------|
| rke2-cp-01 | Control Plane | 192.168.122.10 |
| rke2-worker-01 | Worker | 192.168.122.11 |

### Groups

- `control_plane` - RKE2 server nodes
- `workers` - RKE2 agent nodes
- `all` - All nodes (combined)

## Configuration

### ansible.cfg

The project uses a centralized `ansible.cfg` with the following settings:

- **Inventory**: `inventory/inventory`
- **SSH**: Key-based auth with ControlMaster for performance
- **Privilege Escalation**: sudo via become
- **Facts**: Smart gathering with memory caching
- **Output**: YAML format with profiling enabled

### Connection Variables

Default connection settings (defined in inventory):

- **User**: `ubuntu`
- **Connection**: SSH
- **Become**: Yes (sudo)
- **Key**: `~/.ssh/id_rsa`

## Usage

### Running a Playbook

```bash
# Run all playbooks against all hosts
ansible-playbook playbooks/*.yml

# Run against specific group
ansible-playbook playbooks/site.yml --limit workers

# Check mode (dry-run)
ansible-playbook playbooks/site.yml --check
```

### Inventory Validation

```bash
# List all hosts
ansible-inventory --list

# Graph visualization
ansible-inventory --graph
```

## Development

### Adding a New Role

```bash
# Create role structure
ansible-galaxy init roles/<role-name>
```

### Testing

```bash
# Syntax check
ansible-playbook --syntax-check playbooks/*.yml

# Lint
ansible-lint .
```

## Best Practices

1. **Never commit secrets** - Use Ansible Vault or environment variables
2. **Use idempotent tasks** - Ensure playbooks can be run multiple times safely
3. **Tag tasks** - Use tags for selective execution
4. **Document roles** - Include README in each role
5. **Version control** - Commit changes incrementally

## License

Internal use only - AstroLumina Infrastructure