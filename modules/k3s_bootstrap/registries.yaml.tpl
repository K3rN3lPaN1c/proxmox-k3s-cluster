mirrors:
  docker.io:
    endpoint:
      - "https://${registry_url}"
configs:
  ${registry_url}:
    auth:
      username: ${registry_username}
      password: ${registry_password}
