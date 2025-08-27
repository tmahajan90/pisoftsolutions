# Use the official Ruby image as a base
FROM ruby:3.2.3

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install yarn
RUN npm install -g yarn

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Precompile assets (will be skipped in development)
RUN if [ "$RAILS_ENV" = "production" ]; then bundle exec rails assets:precompile; fi

# Add a script to be executed every time the container starts
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Expose port
EXPOSE 3000

# Start the main process
CMD ["rails", "server", "-b", "0.0.0.0"]
