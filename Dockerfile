# Using the offical Ruby image
FROM ruby:2.6.3

# Default shell as bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Set the working directory within the container
WORKDIR /app

# Install bundler and the dependencies specified in Gemfile
RUN gem install bundler -v 2.4.22 && bundle install --jobs 8

# Copy the application code into the container
COPY . .

# Install Node.js, Yarn, and apt-utils
RUN apt-get update && \
    apt-get install -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get -qy update && \
    apt-get -qy install nodejs && \
    npm install --global yarn

# Precompile assets
RUN RAILS_ENV=production \
  NODE_ENV=production \
  bundle exec rails assets:precompile db:create db:migrate

# Expose the port that the application will run on
EXPOSE 3000

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

# Start the application server
CMD ["bundle", "exec", "rails", "server", "-p", "3000"]
