# nolyporp

In order to deploy infra you need to have valid AWS keys
and put it in `~/.aws/credentials_nolyporp`

Also add same creds to `~/.passwd-s3fs` in format `AWS_KEY_ID:AWS_SECRET_KEY`

State file is local, if you want to put it a in bucket just uncomment backend section in provider.tf

HTTP is used for alb as I do not have valid domain. HTTPS section is commented.
