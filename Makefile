.RECIPEPREFIX = >
.PHONY: format lint test up down logs

format:
>pre-commit run --all-files --hook-stage manual

lint:
>pre-commit run --all-files --hook-stage manual

test:
>pytest -q

up:
>docker compose up -d

down:
>docker compose down

logs:
>docker compose logs -f
