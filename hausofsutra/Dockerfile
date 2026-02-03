FROM docker.io/library/python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    cron \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir instaloader

# Create non-root user
RUN useradd -m -s /bin/bash syncuser

# Setup directories
WORKDIR /app
RUN mkdir -p /home/syncuser/.ssh /var/log/hausofsutra && \
    chown -R syncuser:syncuser /home/syncuser /var/log/hausofsutra

# Copy scripts
COPY entrypoint.sh /entrypoint.sh
COPY sync.sh /app/sync.sh
COPY crontab /etc/cron.d/hausofsutra-cron

RUN chmod +x /entrypoint.sh /app/sync.sh && \
    chmod 0644 /etc/cron.d/hausofsutra-cron && \
    crontab -u syncuser /etc/cron.d/hausofsutra-cron

ENTRYPOINT ["/entrypoint.sh"]
