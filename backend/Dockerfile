FROM python:3.12-slim

# Set workdir
WORKDIR /app

# Install build dependencies for mysqlclient + netcat for wait script
RUN apt-get update && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    python3-dev \
    libssl-dev \
    pkg-config \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Upgrade pip and install dependencies
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY . .

# Make wait-for-db.sh executable
RUN chmod +x wait-for-db.sh

# Expose port
EXPOSE 8000

# Run backend with wait-for-db
CMD ["./wait-for-db.sh"]
