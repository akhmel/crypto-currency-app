# syntax = docker/dockerfile:1

# This Dockerfile is designed for development mode with hot reloading and development dependencies

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages including development tools
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    build-essential \
    git \
    libpq-dev \
    pkg-config \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="" \
    NODE_ENV="development"

# Install application gems including development dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

# Install Node.js dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p tmp/pids tmp/sockets log && \
    chmod -R 755 tmp log

# Create a non-root user for development
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails
USER 1000:1000

# Expose ports for Rails server and Vite dev server
EXPOSE 3000 3036

# Development entrypoint script
COPY --chown=rails:rails docker-entrypoint-dev.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint-dev.sh

# Start development servers
ENTRYPOINT ["/usr/bin/docker-entrypoint-dev.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
