FROM alpine:latest
# Choosing latest - I do not care about idempotency in this Dockerfile, this should alway build latest possible image and will broke oneday for unforseen issues;-)

# FROM amazonlinux:latest
# --> did not used, it's 556 MB with pip+ansible. But with aws tooling in and maintenance by AWS, is better choice I guess. But as I am not using AWS docker repo, smaller is better in case Fargate does not cache docker containers (he probably did, but just in case). But size could be reduced via multi-stage builds.

RUN apk add ansible coreutils py3-pip && pip3 install --user boto3 awscli  && rm -rf /var/cache/apk/*
# Altenative is installation it via pip or compiling and multi-stage build. py3-boto does not work with ansible, pip install ansible requires gcc. Thus quickest seems ^^.
# In this case we rely on apk maintainers of Ansible package. So we generally get latest version, but sometimes we will be behind official release.
# Coreutils is installed, so we can enjoy date -d argument in ansible playbook.

COPY src /app
WORKDIR /app
# Not really sure about way company settled usual app-logic destinations. We do /srv/app_name, i will do app for simplicity.

CMD ansible-playbook update-public-page.yaml -i prod
