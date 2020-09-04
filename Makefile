.PHONY: test

test:
	docker-compose run -T --rm -e "RAILS_ENV=test" web rake test $(ARGS)

rake:
	docker-compose run --rm -e "RAILS_ENV=test" web rake $(ARGS)
