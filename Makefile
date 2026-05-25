.PHONY: install up down logs

install:
	docker-compose build
	docker-compose run --no-deps --rm web bundle exec rails new . --force --database=postgresql --skip-bundle --skip-test
	docker-compose build
	docker-compose run --rm web bundle exec rails db:create

up:
	docker-compose up

down:
	docker-compose down

logs:
	docker-compose logs -f web
