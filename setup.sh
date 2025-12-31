#!/bin/bash
# Monitoring Stack Setup Script
# This script helps you configure the monitoring stack for your environment

set -e

CONFIG_FILE="config.yml"
EXAMPLE_FILE="config.yml.example"
INVENTORY_FILE="inventory"
GROUP_VARS_DIR="group_vars"
MONITORING_VARS="group_vars/monitoring.yml"
NODES_VARS="group_vars/nodes.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Monitoring Stack Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if config.yml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Creating configuration file from template...${NC}"
    if [ -f "$EXAMPLE_FILE" ]; then
        cp "$EXAMPLE_FILE" "$CONFIG_FILE"
        echo -e "${GREEN}✓${NC} Created $CONFIG_FILE from template"
        echo ""
        echo -e "${YELLOW}Please edit $CONFIG_FILE with your settings, then run this script again.${NC}"
        echo ""
        exit 0
    else
        echo -e "${YELLOW}✗${NC} Template file $EXAMPLE_FILE not found!"
        exit 1
    fi
fi

# Check if Python YAML parser is available (for parsing config.yml)
PYTHON_YAML_AVAILABLE=false
if python3 -c "import yaml" 2>/dev/null; then
    PYTHON_YAML_AVAILABLE=true
else
    echo -e "${YELLOW}PyYAML not found. Attempting to install...${NC}"
    pip3 install --user pyyaml 2>/dev/null && PYTHON_YAML_AVAILABLE=true || {
        echo -e "${YELLOW}PyYAML installation failed.${NC}"
        echo -e "${YELLOW}You can install it manually: pip3 install pyyaml${NC}"
        echo ""
        echo "Alternatively, configure manually:"
        echo "  1. Edit $INVENTORY_FILE with your hosts"
        echo "  2. Create $GROUP_VARS_DIR/monitoring.yml with your settings"
        echo "  3. See QUICKSTART.md for manual configuration"
        echo ""
        read -p "Continue with manual configuration? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    }
fi

echo -e "${BLUE}Reading configuration from $CONFIG_FILE...${NC}"

# Create group_vars directory
mkdir -p "$GROUP_VARS_DIR"

if [ "$PYTHON_YAML_AVAILABLE" = true ]; then
# Generate inventory from config.yml
python3 << 'PYTHON_SCRIPT'
import yaml
import sys

try:
    with open('config.yml', 'r') as f:
        config = yaml.safe_load(f)
    
    # Generate inventory
    inventory_content = []
    inventory_content.append("[monitoring]")
    for host in config.get('inventory', {}).get('monitoring_hosts', []):
        if 'ansible_host' in host:
            inventory_content.append(f"{host['name']} ansible_host={host['ansible_host']}")
        else:
            inventory_content.append(host['name'])
    
    inventory_content.append("")
    inventory_content.append("[nodes]")
    for host in config.get('inventory', {}).get('node_hosts', []):
        if 'ansible_host' in host:
            inventory_content.append(f"{host['name']} ansible_host={host['ansible_host']}")
        else:
            inventory_content.append(host['name'])
    
    with open('inventory', 'w') as f:
        f.write('\n'.join(inventory_content))
    
    # Generate group_vars
    import os
    os.makedirs('group_vars', exist_ok=True)
    
    # Monitoring vars
    monitoring_vars = {
        'prometheus_port': config.get('prometheus', {}).get('port', 9090),
        'prometheus_scrape_interval': config.get('prometheus', {}).get('scrape_interval', '15s'),
        'prometheus_data_dir': config.get('prometheus', {}).get('data_dir', '/opt/prometheus'),
        'grafana_port': config.get('grafana', {}).get('port', 3000),
        'grafana_data_dir': config.get('grafana', {}).get('data_dir', '/opt/grafana'),
        'alertmanager_port': config.get('alertmanager', {}).get('port', 9093),
        'alertmanager_data_dir': config.get('alertmanager', {}).get('data_dir', '/opt/alertmanager'),
        'alertmanager_email_to': config.get('alertmanager', {}).get('email', {}).get('to', ''),
        'alertmanager_email_from': config.get('alertmanager', {}).get('email', {}).get('from', ''),
        'alertmanager_email_smarthost': config.get('alertmanager', {}).get('email', {}).get('smarthost', ''),
        'alertmanager_email_username': config.get('alertmanager', {}).get('email', {}).get('auth_username', ''),
        'alertmanager_email_password': config.get('alertmanager', {}).get('email', {}).get('auth_password', ''),
        'monitoring_network_name': config.get('containers', {}).get('network_name', 'monitoring-net'),
    }
    
    with open('group_vars/monitoring.yml', 'w') as f:
        f.write("# Monitoring Server Variables\n")
        f.write("# Generated from config.yml\n\n")
        for key, value in monitoring_vars.items():
            f.write(f"{key}: {repr(value)}\n")
    
    # Nodes vars
    nodes_vars = {
        'node_exporter_port': config.get('node_exporter', {}).get('port', 9100),
    }
    
    with open('group_vars/nodes.yml', 'w') as f:
        f.write("# Node Variables\n")
        f.write("# Generated from config.yml\n\n")
        for key, value in nodes_vars.items():
            f.write(f"{key}: {repr(value)}\n")
    
    # Update ansible.cfg if needed
    ansible_cfg_updates = {
        'remote_user': config.get('ansible', {}).get('remote_user', 'ansible'),
        'become_user': config.get('ansible', {}).get('become_user', 'root'),
        'become_ask_pass': str(config.get('ansible', {}).get('ask_become_pass', False)).lower(),
    }
    
    print("Configuration generated successfully!")
    print(f"  - Inventory: {len(config.get('inventory', {}).get('monitoring_hosts', []))} monitoring host(s)")
    print(f"  - Inventory: {len(config.get('inventory', {}).get('node_hosts', []))} node host(s)")
    
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

    CONFIG_SUCCESS=$?
else
    echo -e "${YELLOW}Using manual configuration method...${NC}"
    CONFIG_SUCCESS=1
fi

if [ $CONFIG_SUCCESS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Configuration files generated successfully!"
    echo ""
    echo "Generated files:"
    echo "  - inventory (updated)"
    echo "  - group_vars/monitoring.yml"
    echo "  - group_vars/nodes.yml"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Review the generated files"
    echo "  2. Test connectivity: ansible all -m ping"
    echo "  3. Deploy: ansible-playbook playbooks/monitoring-stack.yml"
else
    echo -e "${YELLOW}Using manual configuration method...${NC}"
    echo ""
    echo "Please configure manually:"
    echo "  1. Edit $INVENTORY_FILE"
    echo "  2. Edit group_vars/*.yml files"
fi

