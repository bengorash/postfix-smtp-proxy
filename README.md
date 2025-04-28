
# Postfix Native SMTP Service

This repository provides a Postfix-based SMTP service that uses native Postfix features to prevent mail loops, rewrite recipient addresses, selectively relay emails, and reject emails based on a sender:recipient blacklist. It replaces the original Python-based SMTP proxy with a simpler, more performant configuration.

## Features

* **Loop Prevention** : Detects and rejects mail loops using header checks.
* **Recipient Rewriting** : Appends `+relay` to recipient addresses to avoid loops.
* **Selective Relaying** : Routes specific domains (e.g., `gmail.com`) to their SMTP servers.
* **Blacklist** : Rejects emails based on sender:recipient pairs defined in `/etc/postfix/blacklist`.
* **Logging** : Tracks mail flow, rejections, and actions via `/var/log/maillog` and custom `X-Processed` headers.

## Setup

1. **Clone the Repository** :

```bash
   git clone https://github.com/bengorash/postfix-smtp-proxy
   cd postfix-smtp-proxy
```

1. **Build and Run the Docker Container** :

```bash
   docker build -t postfix-native .
   docker run -p 25:25 --name postfix -d postfix-native
```

1. **Verify Configuration** :

* Check `/var/log/maillog` inside the container for mail flow and errors:
  ```bash
  docker exec -it postfix tail -f /var/log/maillog
  ```
* Ensure Postfix is running:
  ```bash
  docker exec -it postfix postfix status
  ```

## Configuration Files

* `/etc/postfix/main.cf`: Core Postfix settings, including relay, mapping, and blacklist restrictions.
* `/etc/postfix/master.cf`: SMTP service with verbose logging.
* `/etc/postfix/recipient_canonical`: Rewrites `user@togotrek.com` to `user+relay@togotrek.com`.
* `/etc/postfix/transport`: Routes `gmail.com` to `smtp.gmail.com:587`.
* `/etc/postfix/header_checks`: Detects loops and adds `X-Loop` and `X-Processed` headers.
* `/etc/postfix/blacklist`: Lists sender:recipient pairs to reject (e.g., `sender1@example.com,user@togotrek.com REJECT`).
* `/etc/rsyslog.d/postfix.conf`: Configures `rsyslog` to write Postfix logs to `/var/log/maillog`.

## Blacklist

* **File** : `/etc/postfix/blacklist`
* **Format** : `sender@domain.com,recipient@domain.com REJECT Blacklist rejection for sender:recipient`
* **Example** :

```
  sender1@example.com,user@togotrek.com REJECT Blacklist rejection for sender1:user
```

* **Update** : Edit the file and run `postmap /etc/postfix/blacklist` to apply changes.
* **Logs** : Rejections appear in `/var/log/maillog`, e.g., “554 5.7.1 Blacklist rejection for sender1:user”.

## Testing

1. Send an email to `user@togotrek.com` and verify it is rewritten to `user+relay@togotrek.com`.
2. Send an email that triggers a loop (e.g., relaying back to `togotrek.com`) and confirm it is rejected with “Message loop detected” in the logs.
3. Send an email to a `gmail.com` address and ensure it routes via `smtp.gmail.com:587`.
4. Send an email from a blacklisted sender:recipient pair (e.g., `sender1@example.com` to `user@togotrek.com`) and verify it is rejected with “Blacklist rejection” in the logs.
5. Check email headers for `X-Processed` and `X-Loop` entries.

## Logging

* **Location** : Logs are written to `/var/log/maillog`.
* **Details** :
* SMTP interactions are logged with verbose mode (`-v` in `master.cf`).
* Loop rejections include “Message loop detected”.
* Blacklist rejections include “Blacklist rejection for sender:recipient라는 사용자는 다음을 좋아합니다.
* **Example Log Entry** :

```
  Apr 26 13:45:23 mail postfix/smtpd[1234]: NOQUEUE: reject: RCPT from ...: 554 5.7.1 Message loop detected
  Apr 26 13:45:24 mail postfix/smtpd[1235]: NOQUEUE: reject: RCPT from ...: 554 5.7.1 Blacklist rejection for sender1:user
  Apr 26 13:45:25 mail postfix/smtpd[1236]: Adding X-Processed: Processed by mail.togotrek.com at Sat, 26 Apr 2025 13:45:25 +0000
```

## Notes

* Replace `togotrek.com` with your domain in all configuration files.
* The original attachment replacement feature is not supported. Contact the maintainer if you need a custom content filter for this.
* For production, secure the SMTP service with TLS and authentication (not included in this setup).
* Update the blacklist by editing `/etc/postfix/blacklist` and running `postmap /etc/postfix/blacklist`.

## Troubleshooting

* **Mail not delivered** : Check `/var/log/maillog` for errors and verify `main.cf` settings.
* **Loops not detected** : Ensure `header_checks` rules match your domain and are applied.
* **Rewriting issues** : Verify `recipient_canonical` syntax and `postmap` compilation.
* **Blacklist not working** : Confirm `blacklist` format, run `postmap /etc/postfix/blacklist`, and check logs for rejection messages.
* **Logging issues** : Check `/var/log/syslog` or `/var/log/mail.log` if `/var/log/maillog` is empty.

For support, open an issue on the GitHub repository.
