# README

This is a starter Rails app setup with Docker. Dockerfile contains 3 stages:

- development
- build
- production

which means that the same Dockerfile can be used to build development and production.

## Dev build

To build for dev, you can use `docker componse`:

```sh
docker compose up -d
```

You can also use Docker CLI:

```sh
docker image build --target=development --build-arg RAILS_ENV_ARG=development --build-arg BUNDLE_DEPLOYMENT_ARG=0 --build-arg BUNDLE_WITHOUT_ARG= -t app:1.0 . --no-cache

docker container run -dit -p 3000:3000 --mount type=bind,source="$(pwd)",target=/rails --name app app:1.0
```

## Production build

```sh
docker image build -t app-prod:1.0 .
```
