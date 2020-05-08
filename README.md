# Homework

## Documentation
### Basic links
- [HTML is served from S3 via Bucket hosting, for enabling HTTPS CloudFront is easiest.](http://homework.itchy.cz.s3-website.eu-central-1.amazonaws.com)
- [Dataset archive is publicly accessible but provides no directory index -> you need to guess date;-)](https://s3.eu-central-1.amazonaws.com/homework.itchy.cz/archive/covid-19/05-06-2020.csv)
- [Builded artefact rot in Dockerhub](https://hub.docker.com/r/zrudko/homework)

### Service updates
Each commit to [dockerhub master](https://github.com/westfood/homework) triggers new docker build in [Dockerhub]((https://hub.docker.com/r/zrudko/homework)). New artefacts rewrites older ones. To keep older artefacts in dockerhub, we should use tags. But it's overkill for homework.

Fargate will (hopefully) pull new version of image from Dockerhub when task is scheduled.

### Prepare AWS
This will prepare ECS cluster called **homework** for running below mentioned dockerized playbook as a scheduled task. It should be idempotent - so there should be no issue running it multiple times -> thus this step could be part some pipeline. Secrets would be provided from runner environment (be it jenkins, github actions or whatbver.)
- ```docker run --env-file aws-credentials zrudko/homework:latest ansible-playbook deploy.yaml -i prod```
- provide env-file with your credentials such as, use filename aws-credentials ideally as it's contained in gitignore to mitigate hasty commits with plaintext credentials.
```bash
AWS_ACCESS_KEY_ID=NOT_BIG_SECRET
AWS_SECRET_ACCESS_KEY=SECRET
AWS_REGION=eu-central-1
```
- It will create S3 bucket: homework.itchy.cz, it's defined via [ansible declaration](src/prod)

### Service for updating dataset
Via running [docker image zrudko/homework]((https://hub.docker.com/r/zrudko/homework)) we get dataset from COVID-19 [repo](https://github.com/CSSEGISandData/COVID-19) maintained by John Hopkins University. It actually just ansible playbook. Python + boto3 as lambda function would be better approach, but this seemed quicker and it's DSL approach. So Fargate pull and run ```zrudko/homework:latest```. That's it.
- Dockerfile CMD is set to run ansible playbook which will get new dataset, push it to S3 archive and publish czech related data to S3 as HTML. In AWS credentials to access S3 should be provided by IAM role.
- ```docker run zrudko/homework:latest```
- provide argument ```--env-file aws-credentials``` if you want to run service from your computer.
- It is meant to run as Fargate task which is triggered by scheduler.
- Service is stupid. It's trying to get dataset from previous day. If fails, it should not change published html or archive. There is no error handling.

### Before going to production
- If dataset is in Github and owned by 3rd party, we should find good way to monitor repository updates. Maybe using github API for periodical checks and trigger updates based it. Main issue witn covid-19 repo is we are getting new datasets with delay because of -1 day hack while requesting dataset. I would like to have something like this push based, not polling based.
- Switch from Fargate with ansible to Lambda function. Run python function when repo is updated.
- Publish HTML via CloudFront to use HTTPS and enjoy caching (and deal with cache invalidations).
- Build and deployment should be handled by pipeline runner. Secrets should be provided to automation. For my projects I would go with Github actions and build pipelines there. If bitbucket I would go with their service.

## Initial thinking
- Fargate with scheduled task
  - docker
    - getting dataset
      - optional: check file hash before putting to S3, if some file has been updated
    - parse for latest data
    - update table in S3
    - optional: S3 as https via Cloudfront / update cache afterwards (maybe S3 could do https out of box)

- Operation
  - Fargate + task defintion via terraform
    - check complexity of cloudformation versus Terraform

- Actualy best solution would be python in lambda for getting URL and publishing to S3. But then there would be no place for Ansible and not much place for dockerization. Maybe dockerization would be useful for keeping all deployment/app-logic related stuff in one place.

## Homework definition

### Goal
Show the ability to automate the deployment of dockerized application Infrastructure and tools:

- AWS EC2
- AWS S3
- Docker and your preferred docker image
- Ansible
- Python or shell

### Task
1. Download regularly (e.g. daily / hourly) some dataset from the free data provider. If you down know any, choose from:
a. https://github.com/CSSEGISandData/COVID-19/
b. https://openweathermap.org/current
1. Store downloaded dataset to S3 bucket
2. From every downloaded dataset, extract some specific data (eg data relevant for Czechia, Prague, ...)
3. Display all extracted data using a single HTML page served from S3. A simple table is enough.

### Instructions
- Use well-known languages (preferable Python 3 or shell) to create scripts/application
- Create a docker to encapsulate the application logic
- Use latest Ansible to create roles and playbooks
- Put all your source code in a public git repository (e.g. Github)
- Use Readme.MD file for the documentation (while evaluating we will use it to run the code)
- If you find problems, or not implement something, you should mention it there
- You don't need to provide automation for AWS infrastructure (EC2, S3) setup but you should document it

### Bonus points
- Replace EC2 with AWS serverless offering
- Document the next steps to make this small app being ready for production
- Automate even the infrastructure setup (cloudformation, terraform)
- Create a CI / CD pipelines
- Use your imagination and provide more than expected
