
# Postfix SMTP Proxy with Loop Prevention

This project implements a Docker container with Postfix configured as an SMTP proxy, featuring built-in loop prevention and blacklist capabilities.

## Features

- **SMTP Proxy**: Relays emails through Postfix
- **Loop Prevention**: Built-in mechanisms to detect and prevent mail loops
- **Blacklist Support**: Block specific recipient addresses
- **Header-Based Detection**: Custom header checks to identify potential loops

## Usage

### Building the Container

```bash
# Clone the repository
git clone https://github.com/bengorash/postfix-smtp-proxy.git
cd postfix-smtp-proxy

# Build the Docker image
docker build -t postfix-native .
```

### Running the Container

```bash
# Run on port 25 (may require root or specific permissions)
docker run -p 25:25 --name postfix -d postfix-native

# Alternative: Run on port 2525 mapped to internal port 25
docker run -p 2525:25 --name postfix -d postfix-native
```

### Testing the SMTP Server

You can test if the server is working using a command like:

```bash
# Using the SMTP protocol directly
telnet localhost 25

# Or on the alternative port
telnet localhost 2525
```

Once connected, you should be able to interact with the SMTP server.

## Configuration Files

- **main.cf**: Main Postfix configuration
- **master.cf**: Postfix services configuration
- **header_checks**: Rules for checking and adding headers
- **recipient_canonical**: Address rewriting rules
- **transport**: Mail routing configuration
- **blacklist**: List of blocked recipient addresses

## Customizing

### Adding Blacklist Entries

Edit the `etc/postfix/blacklist` file to add more blocked recipient addresses:

```
user@example.com REJECT This recipient is blacklisted
```

Then rebuild the image or update the file in a running container with:

```bash
docker exec -it postfix postmap /etc/postfix/blacklist
docker exec -it postfix postfix reload
```

### Modifying Header Checks

Edit `etc/postfix/header_checks` to customize the loop detection logic and rebuild the image.

## Troubleshooting

If the container starts but Postfix doesn't appear to be listening on port 25:

1. Check the logs: `docker logs postfix`
2. Verify Postfix is running: `docker exec -it postfix postfix status`
3. Check network settings: `docker exec -it postfix netstat -tulnp | grep :25`

## Notes

- Running on port 25 often requires elevated privileges or specific cloud provider settings
- For production use, consider adding proper SMTP authentication and TLS encryption
