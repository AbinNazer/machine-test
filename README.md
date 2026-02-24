# 🚀 Dockerized Full-Stack Application  
### Django 6 + React + MySQL + Docker Compose + CI

---

## 📌 Project Overview

This project is a fully containerized full-stack web application built using:

- **Backend:** Django 6 + Django REST Framework  
- **Frontend:** React  
- **Database:** MySQL 8  
- **WSGI Server:** Gunicorn  
- **Containerization:** Docker & Docker Compose  
- **CI/CD:** GitHub Actions  

The project demonstrates practical DevOps concepts including container orchestration, environment-based configuration, production server setup, database readiness handling, and CI validation.

---

# 🐳 Docker Implementation Details

## 🔹 Backend Dockerfile

### Base Image Used

```dockerfile
FROM python:3.12-slim
```

### 🛠 System Dependencies Installed

```dockerfile
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    python3-dev \
    libssl-dev \
    pkg-config \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*
```

### Why These Were Installed

- `default-libmysqlclient-dev` → Required for `mysqlclient`
- `build-essential` → Needed to compile Python packages
- `python3-dev` → Required for building native extensions
- `libssl-dev` → Secure DB connection support
- `pkg-config` → Dependency resolution
- `netcat-openbsd` → Used in `wait-for-db.sh` to check DB readiness

This ensures the backend container can properly build and connect to MySQL.

---

### 📦 Python Dependency Installation

```dockerfile
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
```

- Dependencies installed inside container  
- No cached layers kept  
- Clean production image  

---

### ⏳ Database Readiness Handling

```dockerfile
CMD ["./wait-for-db.sh"]
```

The container does not directly start Django.

Instead, it runs a custom script that:

- Waits for MySQL to be available  
- Prevents race condition errors  
- Starts Gunicorn only after DB is ready  

---

### 🚀 Production Server

Inside `wait-for-db.sh`:

```bash
gunicorn backend.wsgi:application --bind 0.0.0.0:8000 --timeout 120
```

Gunicorn is used instead of Django’s development server to ensure production readiness.

---

## 🔹 Frontend Dockerfile (Multi-Stage Build)

### Build Stage

```dockerfile
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
```

What happens here:

- Uses lightweight Alpine image  
- Installs dependencies  
- Builds optimized React production files  
- Generates `/build` directory  

---

### Production Stage

```dockerfile
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
```

- Only static files are copied  
- Node runtime is not included  
- Smaller, secure production image  
- Default nginx config serves static React app  

Frontend runs on:

```
http://localhost:3000
```

(Port 3000 mapped to container port 80)

---

# 🗄 Docker Compose Configuration

Defined services:

## 1️⃣ MySQL Service

```yaml
db:
  image: mysql:8
  volumes:
    - mysql_data:/var/lib/mysql
```

- Uses environment variables from `.env`
- Persistent storage using named volume
- Exposed on port 3306

---

## 2️⃣ Backend Service

```yaml
backend:
  build: ./backend
  depends_on:
    - db
  command: ["./wait-for-db.sh"]
  ports:
    - "8000:8000"
```

- Built from custom Dockerfile  
- Waits for database before starting  
- Runs Gunicorn server  

---

## 3️⃣ Frontend Service

```yaml
frontend:
  build: ./frontend
  depends_on:
    - backend
  ports:
    - "3000:80"
```

- Multi-stage React build  
- Served via nginx container  

---

# 🔐 Environment Configuration

Used `.env` file for:

- MYSQL_DATABASE  
- MYSQL_USER  
- MYSQL_PASSWORD  
- MYSQL_HOST  
- MYSQL_PORT  
- DJANGO_SECRET_KEY  
- DJANGO_DEBUG  

Loaded inside Django using:

```python
load_dotenv()
```

This avoids hardcoded credentials and follows 12-factor app principles.

---

# 🔄 Database Commands Used

After containers start:

### Run migrations

```bash
docker exec -it <backend-container> python manage.py migrate
```

### Create superuser

```bash
docker exec -it <backend-container> python manage.py createsuperuser
```

Access admin:

```
http://localhost:8000/admin
```

---

# 🔄 CI/CD – GitHub Actions

Workflow file:

```
.github/workflows/ci.yml
```

Pipeline actions:

- Triggered on push to `main`
- Builds backend Docker image
- Builds frontend Docker image
- Validates Docker build success

This ensures the application builds successfully before deployment.

---

# 💾 Persistent Storage

```yaml
volumes:
  mysql_data:
```

Ensures MySQL data is not lost when containers restart.

---

# 🧠 DevOps Concepts Demonstrated

- Multi-container orchestration  
- Production-ready backend server  
- Multi-stage Docker builds  
- Database readiness handling  
- Persistent volumes  
- Environment variable management  
- Service-based container networking  
- CI pipeline integration  

---

# 🚀 How to Run

```bash
docker compose up -d --build
```

Then:

```bash
docker exec -it <backend-container> python manage.py migrate
```

---
# ⚙ Backend Configuration (Based on Machine Test Requirement)

According to the machine test instructions:

- The default Django database configuration had to be replaced.
- The MySQL configuration block needed to be uncommented.
- All database credentials and `SECRET_KEY` must be loaded from `.env`.
- No credentials should be hardcoded.
- DEBUG must support production configuration.
- Environment variables must work properly inside Docker.

Below are the changes implemented in `settings.py`.

---

## 🔐 Environment Variable Handling

Environment variables are loaded using `python-dotenv`:

```python
import os
from dotenv import load_dotenv
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(os.path.join(BASE_DIR, '.env'))
```

This ensures:

- Secure credential management
- No hardcoded secrets
- Compatibility with Docker environment variables

---

## 🔑 SECRET_KEY Configuration

```python
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
```

✔ SECRET_KEY is not hardcoded  
✔ Loaded securely from `.env`  

---

## 🛡 DEBUG Configuration (Production Ready Support)

```python
DEBUG = os.getenv("DJANGO_DEBUG") == "True"
```

This allows:

- `DEBUG=True` for development
- `DEBUG=False` for production
- Easy switching via environment variables

---

## 🗄 MySQL Database Configuration

The default SQLite configuration was replaced with MySQL:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv("MYSQL_DATABASE"),
        'USER': os.getenv("MYSQL_USER"),
        'PASSWORD': os.getenv("MYSQL_PASSWORD"),
        'HOST': os.getenv("MYSQL_HOST"),
        'PORT': os.getenv("MYSQL_PORT"),
    }
}
```

✔ Credentials loaded from `.env`  
✔ No hardcoded values  
✔ Uses Docker service name (`db`) as host  
✔ Proper environment-based configuration  

---

## 🌐 CORS Configuration

To allow frontend-backend communication:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
]

CORS_ALLOW_ALL_ORIGINS = True
```

This ensures the React frontend can communicate with the Django backend.

---

## 📦 Installed Applications

Additional apps configured:

```python
INSTALLED_APPS = [
    ...
    'corsheaders',
    'rest_framework',
    'tasks',
]
```

- `corsheaders` → Handle cross-origin requests
- `rest_framework` → API support
- `tasks` → Custom Django app

---

## 🚀 Production Server Configuration

Instead of using Django's development server:

- Gunicorn is used
- Started via `wait-for-db.sh`
- Backend runs only after MySQL is ready

```bash
gunicorn backend.wsgi:application --bind 0.0.0.0:8000 --timeout 120
```

---

## ✅ Machine Test Requirements Fulfilled

✔ Dockerized Django backend  
✔ MySQL configured properly  
✔ Environment variables used securely  
✔ No credentials hardcoded  
✔ Production-ready DEBUG support  
✔ Docker environment variable handling  
✔ Database readiness handling  
✔ CI pipeline configured  

---

# 🎯 Summary

This project demonstrates a practical, production-oriented Docker setup for a full-stack application using Django, React, and MySQL, with CI validation and container best practices.
