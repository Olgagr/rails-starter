ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim as base

ARG RAILS_ENV_ARG=production
ARG BUNDLE_DEPLOYMENT_ARG=1
ARG BUNDLE_WITHOUT_ARG=development

ENV RAILS_ENV=$RAILS_ENV_ARG \
    BUNDLE_DEPLOYMENT=$BUNDLE_DEPLOYMENT_ARG \
    BUNDLE_WITHOUT=$BUNDLE_WITHOUT_ARG \
    BUNDLE_PATH="/usr/local/bundle"

WORKDIR /rails

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips pkg-config curl postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# development stage
FROM base as development

# Copy application code
COPY . .

## remove root from the container
RUN groupadd -g 500 ror && useradd -u 500 -g ror ror
USER ror:ror

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server","-b","0.0.0.0"]

# build stage
FROM base as build

RUN bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# production stage
FROM base

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]



