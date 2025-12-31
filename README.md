# Monitoring Stack - Ansible Deployment

Automated deployment of Prometheus, Grafana, Alertmanager, and Node Exporter using Ansible and Podman containers.

## 🚀 Quick Start

### Step 1: Clone and Setup

```bash
git clone https://github.com/Hafez292/Monitoring-Stack.git
cd monitoring-stack
chmod +x setup.sh
./setup.sh
```

### Step 2: Customize Configuration

The setup script creates `config.yml` from a template. Edit it with your environment settings:

```bash
nano config.yml
```

**Key settings to customize:**

```yaml
# Your server IPs/hostnames
inventory:
  monitoring_hosts:
    - name: monitoring-server
      ansible_host: 192.168.1.10  # ← Change this
  
  node_hosts:
    - name: node-1
      ansible_host: 192.168.1.11  # ← Change this

# Email alerts configuration
alertmanager:
  email:
    to: your-email@example.com      # ← Your email
    from: alertmanager@example.com
    smarthost: smtp.gmail.com:587   # ← Your SMTP server
    auth_username: your-email@gmail.com
    auth_password: your-app-password # ← Your password
```

### Step 3: Generate Configuration Files

After editing `config.yml`, run the setup script again to generate Ansible files:

```bash
./setup.sh
```

This creates:
- `inventory` - Ansible inventory with your hosts
- `group_vars/monitoring.yml` - Variables for monitoring server
- `group_vars/nodes.yml` - Variables for nodes

### Step 4: Deploy

```bash
# Test connectivity
ansible all -m ping

# Deploy monitoring stack (Prometheus, Grafana, Alertmanager)
ansible-playbook playbooks/monitoring-stack.yml

# Deploy Node Exporter on all nodes
ansible-playbook playbooks/node-exporter.yml
```

### Step 5: Access Services

- **Grafana**: http://YOUR_MONITORING_SERVER:3000 (admin/admin)
- **Prometheus**: http://YOUR_MONITORING_SERVER:9090
- **Alertmanager**: http://YOUR_MONITORING_SERVER:9093

## 📋 Prerequisites

- Ansible 2.9+ or Ansible Navigator
- SSH access to target hosts with sudo privileges
- Python 3 with PyYAML (for setup script)

## ⚙️ Configuration Guide

### Using the Setup Script

The `setup.sh` script makes configuration easy:

1. **First run**: Creates `config.yml` from template
   ```bash
   ./setup.sh
   # Output: Created config.yml from template
   ```

2. **Edit config.yml**: Customize with your settings
   ```bash
   nano config.yml
   ```

3. **Second run**: Generates Ansible files from your config
   ```bash
   ./setup.sh
   # Output: Configuration files generated successfully!
   ```

### Configuration Options in config.yml

| Section | What to Configure |
|---------|-------------------|
| `inventory` | Host IPs and hostnames for monitoring server and nodes |
| `alertmanager.email` | SMTP settings for email alerts |
| `prometheus.port` | Prometheus port (default: 9090) |
| `grafana.port` | Grafana port (default: 3000) |
| `containers.network_name` | Podman network name (default: monitoring-net) |

### Example: Gmail Configuration

```yaml
alertmanager:
  email:
    to: your-email@gmail.com
    from: alertmanager@gmail.com
    smarthost: smtp.gmail.com:587
    auth_username: your-email@gmail.com
    auth_password: your-app-password  # Use App Password, not regular password
```

**Note**: For Gmail, create an [App Password](https://support.google.com/accounts/answer/185833) instead of using your regular password.

## 🏗️ Architecture

All containers run on a shared Podman network (`monitoring-net`) for easy communication:

```
┌─────────────────────────────────────┐
│   Podman Network: monitoring-net    │
│                                      │
│  ┌──────────┐  ┌──────────┐       │
│  │Prometheus│  │ Grafana  │       │
│  └──────────┘  └──────────┘       │
│  ┌──────────┐                       │
│  │Alertmanager│                    │
│  └──────────┘                       │
└─────────────────────────────────────┘
         │
         │ Scrapes metrics
         │
┌─────────────────────────────────┐
│   Monitored Nodes               │
│  ┌──────────────┐              │
│  │Node Exporter │              │
│  └──────────────┘              │
└─────────────────────────────────┘
```

## 🎯 Features

- ✅ **Fully Automated**: Setup script generates all configuration
- ✅ **Auto-provisioned Grafana**: Dashboards and datasources configured automatically
- ✅ **Container Network**: All services communicate via Podman network
- ✅ **Auto-start on Reboot**: All containers automatically restart after server reboot
- ✅ **Customizable**: Easy configuration via `config.yml`
- ✅ **Production Ready**: Includes alerting and monitoring

## 📊 Components

| Component | Port | Access URL |
|-----------|------|------------|
| Prometheus | 9090 | http://monitoring-server:9090 |
| Grafana | 3000 | http://monitoring-server:3000 |
| Alertmanager | 9093 | http://monitoring-server:9093 |
| Node Exporter | 9100 | http://node:9100/metrics |

## 🔧 Usage

### Deploy Everything

```bash
# Deploy monitoring server
ansible-playbook playbooks/monitoring-stack.yml

# Deploy Node Exporter
ansible-playbook playbooks/node-exporter.yml
```

### Using Ansible Navigator

```bash
ansible-navigator run playbooks/monitoring-stack.yml
ansible-navigator run playbooks/node-exporter.yml
```

### Verify Deployment

```bash
# Check containers
ssh user@monitoring-server 'podman ps'

# Test services
curl http://monitoring-server:9090  # Prometheus
curl http://monitoring-server:3000  # Grafana
```

## 🔄 Auto-Start on Reboot

All containers are configured to automatically start on server reboot using systemd services:

- ✅ Systemd services are automatically generated and enabled
- ✅ Containers start automatically when the server boots
- ✅ Containers automatically restart if they crash
- ✅ No manual intervention needed after deployment

**How it works:**
- Each container gets a systemd service file in `/etc/systemd/system/`
- Services are enabled to start on boot
- Uses system-level systemd (requires `become: true`)

**Verify auto-start:**
```bash
# Check services are enabled
systemctl list-unit-files | grep container-

# Check service status
systemctl status container-prometheus.service
systemctl status container-grafana.service

# Test: Reboot server and verify containers start
sudo reboot
# After reboot, check:
podman ps
systemctl status container-prometheus.service
```

**Manual service management:**
```bash
# Start a service
sudo systemctl start container-prometheus.service

# Stop a service
sudo systemctl stop container-prometheus.service

# Restart a service
sudo systemctl restart container-prometheus.service

# View service logs
sudo journalctl -u container-prometheus.service -f
```

## 🐛 Troubleshooting

### Setup Script Issues

**Problem**: PyYAML not found
```bash
# Install PyYAML
pip3 install pyyaml
# Or configure manually (see QUICKSTART.md)
```

**Problem**: Configuration not generated
- Check that `config.yml` exists
- Verify YAML syntax is correct
- Run `./setup.sh` again after fixing

### Deployment Issues

**SSH Connection Failed**
```bash
# Test SSH access
ssh user@hostname
# Configure SSH keys: ssh-copy-id user@hostname
```

**Containers Not Starting**
```bash
# Check logs
podman logs prometheus
podman logs grafana

# Check network
podman network ls
podman network inspect monitoring-net
```

**Grafana Can't Connect to Prometheus**
- Verify both containers are on `monitoring-net` network
- Check: `podman inspect prometheus | grep NetworkMode`
- Check: `podman inspect grafana | grep NetworkMode`

## 📁 Project Structure

```
monitoring-stack/
├── config.yml.example      # Configuration template
├── setup.sh                 # Setup script (run this first!)
├── config.yml               # Your configuration (edit this)
├── inventory                # Generated from config.yml
├── group_vars/              # Generated from config.yml
├── playbooks/
│   ├── monitoring-stack.yml # Deploy Prometheus, Grafana, Alertmanager
│   └── node-exporter.yml    # Deploy Node Exporter
└── roles/                   # Ansible roles
```

## 📝 Quick Reference

```bash
# Initial setup
./setup.sh                    # Create config.yml
nano config.yml               # Edit your settings
./setup.sh                    # Generate Ansible files

# Deploy
ansible all -m ping           # Test connectivity
ansible-playbook playbooks/monitoring-stack.yml
ansible-playbook playbooks/node-exporter.yml

# Verify
podman ps                     # Check containers
curl http://server:9090       # Test Prometheus
curl http://server:3000       # Test Grafana
```

## 🤝 Contributing

Contributions welcome! Please submit a Pull Request.

## 📄 License

[Hafez292@NTI_CTI_Carrer_Lanuch Project]

---

