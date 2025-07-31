# 🚀 Redmine Deployment con Ansible y Vagrant
Proyecto para desplegar Redmine usando Ansible para aprovisionar una maquina virtual con Vagrant

## 🎯 Descripcion del proyecto

Este proyecto implementa la instalación automatizada de Redmine con las siguientes características:

- ✅ Ruby gestionado: Uso de asdf para instalar Ruby 3.3.8 (no la versión del SO)
- ✅ Usuario no-root: Redmine ejecutándose con usuario dedicado
- ✅ Proxy reverso: Nginx sirviendo contenido estático y proxy hacia Puma
- ✅ Base de datos: Local en la VM con MySQL 8.0
- ✅ Aprovisionamiento automatizado: Ansible para configuración de la aplicación

## 🏗️ Arquitectura
```
┌─────────────────────────────────────┐
│           VM local                  │ 
├─────────────────────────────────────┤ 
│  Nginx (Proxy Reverso) :80          │
├─────────────────────────────────────┤ 
│  Redmine + Puma : (Socket UNIX)     │ 
├─────────────────────────────────────┤  
│  Ruby 3.3.8 (asdf)                  │ 
├─────────────────────────────────────┤ 
│             MySQL                   │
│        (Base de Datos)              │
└─────────────────────────────────────┘
```

## 🔧 Requisitos 

### Software requerido
- Ansible >= 2.9
- Python >= 3.8
- Vagrant >= 2.4

## 🚀 Instalacion

### 1. Clonar repositorio

```bash
git clone <repo-url>
cd redmine-ansible-entrega
```

### 2. Creacion maquina virtual
```bash
vagrant up
```

## Uso

Una vez creada la maquina virtual y aprovisionada por **playbook.yml**

### 1. Ingreso a VM
```bash
vagrant ssh
```

### 2. Obtener IP
```bash
ip a
```

### 3. Acceder al sitio

Ingresar a http://**ip-vm**

Deberias poder utilizar la aplicacion Redmine

## ⚙️ Configuracion

### Variables de entorno

#### Ansible (`vault/redmine_secrets.yml`)
Debes agregar las credenciales con las cuales quieres crear la base de datos
```yaml
db_user: "redmine"
db_password: "redmine_password"
db_host: "localhost"
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

## 🔒 Seguridad

### Buenas Prácticas Implementadas

- ✅ **Usuario no-root**: Redmine ejecutándose con usuario dedicado
- ✅ **Proxy reverso**: Nginx para optimización y seguridad

## 📝 Notas de Desarrollo

### Estructura de Roles

1. **redmine**: Instalación base y configuración inicial
2. **asdf_ruby**: Gestión de Ruby y configuración de la aplicación
3. **nginx**: Proxy reverso y servido de archivos estáticos

### Flujo de Ejecución

```
1. Vagrant → Creacion maquina virtual
2. Ansible → Aprovisiona la aplicación
3. Verificación → Prueba conectividad y funcionalidad
```

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.
---