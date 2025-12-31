# Quick Start Guide

## 5-Minute Setup

### Step 1: Clone and Configure

```bash
git clone https://github.com/yourusername/monitoring-stack.git
cd monitoring-stack
```

### Step 2: Run Setup Script

```bash
./setup.sh
```

This will create `config.yml` from template. Edit it with your settings:

```yaml
inventory:
  monitoring_hosts:
    - name: monitoring-server
      ansible_host: YOUR_MONITORING_SERVER_IP
  
  node_hosts:
    - name: node-1
      ansible_host: YOUR_NODE_1_IP

alertmanager:
  email:
    to: your-email@example.com
    from: alertmanager@example.com
    smarthost: smtp.gmail.com:587
    auth_username: your-email@gmail.com
    auth_password: your-app-password
```

### Step 3: Generate Configuration

Run setup script again:
```bash
./setup.sh
```

### Step 4: Deploy

```bash
# Test connectivity
ansible all -m ping

# Deploy monitoring stack
ansible-playbook playbooks/monitoring-stack.yml

# Deploy Node Exporter
ansible-playbook playbooks/node-exporter.yml
```

### Step 5: Access Services

- **Grafana**: http://YOUR_MONITORING_SERVER:3000 (admin/admin)
- **Prometheus**: http://YOUR_MONITORING_SERVER:9090
- **Alertmanager**: http://YOUR_MONITORING_SERVER:9093

Done! 🎉

## Manual Setup (Without Python)

If you don't have Python YAML support:

1. **Edit inventory manually:**
   ```ini
   [monitoring]
   monitoring-server ansible_host=YOUR_IP

   [nodes]
   node-1 ansible_host=YOUR_IP
   ```

2. **Create group_vars/monitoring.yml:**
   ```yaml
   alertmanager_email_to: your-email@example.com
   alertmanager_email_from: alertmanager@example.com
   alertmanager_email_smarthost: smtp.gmail.com:587
   alertmanager_email_username: your-email@gmail.com
   alertmanager_email_password: your-password
   ```

3. **Deploy:**
   ```bash
   ansible-playbook playbooks/monitoring-stack.yml
   ansible-playbook playbooks/node-exporter.yml
   ```

