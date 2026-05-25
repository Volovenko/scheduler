.PHONY: build up down logs bash setup migrate seed test swagger lint

build:
	docker-compose up --build -d

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f web

bash:
	docker-compose exec web bash

setup: build
	docker-compose exec web bin/rails db:create db:migrate db:seed

migrate:
	docker-compose exec web bin/rails db:migrate

seed:
	docker-compose exec web bin/rails db:seed

test:
	docker-compose exec -e RAILS_ENV=test web bundle exec rspec

swagger:
	docker-compose exec -e RAILS_ENV=test web bundle exec rails rswag

lint:
	docker-compose exec web bundle exec rubocop
