# 🚀 Redmine Deployment con Ansible y OpenTofu

Proyecto completo para desplegar Redmine en AWS usando Ansible para aprovisionamiento y OpenTofu para infraestructura como codigo.

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#descripción-del-proyecto)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Configuración](#configuración)
- [Troubleshooting](#troubleshooting)

## 🎯 Descripción del Proyecto

Este proyecto implementa la instalación automatizada de Redmine en AWS con las siguientes características:

- ✅ **Ruby gestionado**: Uso de asdf para instalar Ruby 3.3.8 (no la versión del SO)
- ✅ **Usuario no-root**: Redmine ejecutándose con usuario dedicado
- ✅ **Proxy reverso**: Nginx sirviendo contenido estático y proxy hacia Puma
- ✅ **Base de datos externa**: AWS RDS MySQL para persistencia
- ✅ **Infraestructura como codigo**: OpenTofu para gestionar recursos AWS
- ✅ **Aprovisionamiento automatizado**: Ansible para configuración de la aplicación

## 🏗️ Arquitectura

### Entorno AWS
```
┌─────────────────────────────────────┐
│           EC2 Instance              │
├─────────────────────────────────────┤
│  Nginx (Proxy Reverso) :80         │
├─────────────────────────────────────┤
│  Redmine + Puma :3000              │
├─────────────────────────────────────┤
│  Ruby 3.3.8 (asdf)                 │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│           AWS RDS MySQL             │
│        (Base de Datos)             │
└─────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
redmine-ansible-entrega/
├── 📁 roles/
│   ├── 📁 redmine/                    # Instalacion base de Redmine
│   │   ├── 📄 tasks/main.yml
│   │   ├── 📄 templates/
│   │   │   ├── 📄 database.yml.j2
│   │   │   └── 📄 configuration.yml.j2
│   │   └── 📄 files/production.rb
│   ├── 📁 asdf_ruby/                  # Gestion de Ruby con asdf
│   │   ├── 📄 tasks/main.yml
│   │   └── 📄 templates/
│   │       ├── 📄 secrets.yml.j2
│   │       └── 📄 puma-daemon.service.j2
│   └── 📁 nginx/                      # Configuracion de proxy reverso
│       ├── 📄 tasks/main.yml
│       └── 📄 templates/redmine.j2
├── 📁 vault/
│   └── 📄 redmine_secrets.yml         # Credenciales de base de datos
├── 📄 main.tf                         # Recursos principales OpenTofu
├── 📄 variables.tf                    # Variables de entrada
├── 📄 outputs.tf                      # Salidas del despliegue
├── 📄 provider.tf                     # Configuracion del proveedor
├── 📄 terraform.tfvars                # Valores de variables
├── 📄 playbook.yml                    # Playbook principal de Ansible
├── 📄 inventory.ini                   # Inventario de hosts
└── 📄 README.md                       # Este archivo
```

## 🔧 Requisitos

### Software Requerido
- **OpenTofu** >= 1.10.3
- **Ansible** >= 2.9
- **Python** >= 3.8
- **AWS CLI** (configurado con credenciales)

### Credenciales AWS
- Access Key ID
- Secret Access Key
- Región: us-east-1

### Claves SSH
- Clave privada: `~/.ssh/aws`
- Clave pública: `~/.ssh/aws.pub`

## 🚀 Instalación

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd redmine-ansible-entrega
```

### 2. Configurar credenciales AWS
```bash
export AWS_ACCESS_KEY_ID="tu_access_key"
export AWS_SECRET_ACCESS_KEY="tu_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. Generar claves SSH (si no existen)
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/aws -N ""
```

### 4. Configurar variables
Editar `terraform.tfvars`:
```hcl
key_name       = "aws-key-redmine"
public_key_path = "~/.ssh/aws.pub"
```

## 🎮 Uso

### Despliegue Completo

#### 1. Crear Infraestructura con OpenTofu
```bash
# Inicializar OpenTofu
opentofu init

# Verificar plan
opentofu plan

# Aplicar cambios
opentofu apply
```

#### 2. Obtener IP de la instancia
```bash
terraform output instance_ip
```

#### 3. Actualizar inventory
Editar `inventory.ini` con la IP obtenida:
```ini
[redmine]
[IP_DE_LA_INSTANCIA] ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/aws
```

#### 4. Ejecutar Ansible
```bash
# Probar conectividad
ansible redmine -m ping

# Ejecutar playbook
ansible-playbook -i inventory.ini playbook.yml
```

### Verificación

#### 1. Conectividad SSH
```bash
ssh -i ~/.ssh/aws ubuntu@[IP_DE_LA_INSTANCIA]
```

#### 2. Acceso Web
```bash
curl http://[IP_DE_LA_INSTANCIA]
```

#### 3. Servicios
```bash
# Verificar servicios
sudo systemctl status puma-daemon
sudo systemctl status nginx

# Ver logs
sudo journalctl -u puma-daemon -f
sudo tail -f /var/log/nginx/redmine.error.log
```

## ⚙️ Configuración

### Variables de Entorno

#### OpenTofu (`terraform.tfvars`)
```hcl
key_name       = "aws-key-redmine"
public_key_path = "~/.ssh/aws.pub"
```

#### Ansible (`vault/redmine_secrets.yml`)
```yaml
db_user: "redmine"
db_password: "redmine_password"
db_host: "localhost"  # Cambiar a RDS endpoint en AWS
db_port: 3306
db_name: "redmine_production"
db_charset: "utf8mb4"
```

### Configuración de Redmine

#### Base de Datos (`roles/redmine/templates/database.yml.j2`)
```yaml
production:
  adapter: mysql2
  database: {{ db_name }}
  host: {{ db_host }}
  username: {{ db_user }}
  password: {{ db_password }}
```

#### Nginx (`roles/nginx/templates/redmine.j2`)
```nginx
upstream myapp {
  server unix:///var/run/redmine/redmine.sock;
}

server {
  listen 80;
  server_name _;
  root {{ redmine_dir }}/redmine-6.0.6/public;
  
  location / {
    try_files $uri @app;
  }
  
  location @app {
    proxy_pass http://myapp;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

## 🔍 Troubleshooting

### Problemas Comunes

#### 1. Error de conectividad SSH
```bash
# Verificar permisos de clave
chmod 600 ~/.ssh/aws

# Probar conectividad
ssh -i ~/.ssh/aws -o StrictHostKeyChecking=no ubuntu@[IP]
```

#### 2. Error de base de datos
```bash
# Verificar conexión a RDS
mysql -h [RDS_ENDPOINT] -u redmine -p redmine_production
```

#### 3. Error de servicios
```bash
# Reiniciar servicios
sudo systemctl restart puma-daemon
sudo systemctl restart nginx

# Ver logs
sudo journalctl -u puma-daemon -n 50
```

### Logs Importantes

- **Puma**: `/var/log/redmine/puma.log`
- **Nginx**: `/var/log/nginx/redmine.error.log`
- **Rails**: `/opt/redmine/redmine-6.0.6/log/production.log`

## 📊 Monitoreo

### Comandos Útiles

```bash
# Estado de servicios
sudo systemctl status puma-daemon nginx

# Logs en tiempo real
sudo tail -f /var/log/nginx/redmine.access.log
```

## 🔒 Seguridad

### Buenas Prácticas Implementadas

- ✅ **Usuario no-root**: Redmine ejecutándose con usuario dedicado
- ✅ **Security Groups**: Reglas específicas para SSH y HTTP
- ✅ **Claves SSH**: Autenticación por clave en lugar de contraseña
- ✅ **Base de datos externa**: RDS con respaldos automáticos
- ✅ **Proxy reverso**: Nginx para optimización y seguridad

## 📝 Notas de Desarrollo

### Estructura de Roles

1. **redmine**: Instalación base y configuración inicial
2. **asdf_ruby**: Gestión de Ruby y configuración de la aplicación
3. **nginx**: Proxy reverso y servido de archivos estáticos

### Flujo de Ejecución

```
1. OpenTofu → Crea infraestructura AWS
2. Ansible → Aprovisiona la aplicación
3. Verificación → Prueba conectividad y funcionalidad
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
---

**Desarrollado con ❤️ usando Ansible y OpenTofu** 