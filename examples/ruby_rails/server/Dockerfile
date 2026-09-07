FROM ruby:3.4.5-slim
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libyaml-dev libxml2-dev libxslt1-dev pkg-config && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment true && bundle install
COPY . .
RUN RAILS_ENV=test RSWAG_DRY_RUN=0 bundle exec rake rswag:specs:swaggerize
EXPOSE 8000
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:8000", "config.ru"]
