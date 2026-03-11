# SSH

An exercise to test creating keys and logging into an SSH server.

## Key generation and SSH login

```shell
# Use RSA (traditional, widely supported) or ed25519 (modern, recommended)
ssh-keygen -t rsa -b 4096 -C "your@email.com"
ssh-keygen -t ed25519 -C "your@email.com"

# Run docker SSH server (containerfile)
docker pull quay.io/vicenteherrera/example-ssh:latest
docker run -d -p 2222:22 --name ssh-lab \
quay.io/vicenteherrera/example-ssh

# First log in manually, user: student, password: password123
ssh student@localhost -p 2222

# Copying your key to the server (execute on your computer) (Windows: git bash)
ssh-copy-id -p 2222 student@localhost

# Or copy the file manually
cat ~/.ssh/id_ed25519.pub | \
ssh student@localhost -p 2222 "cat >> ~/.ssh/authorized_keys"

# Stop and remove the SSH server container
docker stop ssh-lab && docker rm ssh-lab
```

## Customize your own SSH server container image

```shell
# Modify ssh server container so it can:
# 1) Incorporate your public SSH key
# 2) Modify MOTD (Message of the Day) to say "Hello <your name>"
cd ssh
code dockerfile

# Build and test the new container image
make build

# Follow previous steps to make sure new image works

# Edit container image name, and push to your own Docker registry
code make
docker login
make build
make push
```
