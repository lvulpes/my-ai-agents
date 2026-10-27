# my-ai-agents
Collection of docker containers with different AI agents

# Quick start guide

Rebuild the image when changes have been made:
``` terminal
docker compose build
```

Spin up a container and connect to it:
``` terminal
docker compose run --rm gemini
```

If you want to connect directly to the container to run commands:
``` terminal
docker compose run --rm --entrypoint /bin/bash gemini
```

If you need to verify the container is up:
``` terminal
docker ps
CONTAINER ID   IMAGE                 COMMAND     CREATED         STATUS         PORTS     NAMES
fe2597f08212   recipe-agent-gemini   "gemini"    4 minutes ago   Up 4 minutes             recipe-agent-gemini-run-a08f12471f5c
```
