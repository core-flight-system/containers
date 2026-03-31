# cfsbuildenv-ubuntu22 container

This container is intended to host containerized jobs in workflows

It is not started or built directly from this docker compose because 
it would only be started via workflow jobs when needed.

It must be built separately using `docker build`, for example:

```
docker build -t cfsbuildenv-ubuntu22:latest .
```

