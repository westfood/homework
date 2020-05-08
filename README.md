# Homework

## Documentation
### Basic links
- [HTML is served from S3 via Bucket hosting, for enabling HTTPS CloudFront is easiest.](http://homework.itchy.cz.s3-website.eu-central-1.amazonaws.com)
- [Dataset archive is publicly accessible but provides no directory index -> you need to guess date;-)](https://s3.eu-central-1.amazonaws.com/homework.itchy.cz/archive/covid-19/05-06-2020.csv)
- [Builded artefact rot in Dockerhub](https://hub.docker.com/r/zrudko/homework)

### Service updates
Each commit to [github/westfood/homework:master](https://github.com/westfood/homework) triggers Dockerhub to build image [zrudko/homework:latest](https://hub.docker.com/r/zrudko/homework). New build artefact rewrites older ones. To archive previous artefacts we should employ tagging strategy. But it's overkill for this homework.

Fargate will pull new version of image from Dockerhub when task is scheduled (every 6 hours).

### Prepare AWS environment for service | WIP
This playbook prepare ECS cluster called **homework-runner** for running dockerized service as a scheduled task every 6 hours. It should be idempotent - so there should be no issue running it again and again. Thus this step could be part deployment pipeline. Secrets would be provided from runner environment (be it jenkins, github actions or whatever.) S3 bucket **homework.itchy.cz** with enabled bucket hosting is created to provide index page for HTTP endpoint and archive of full datasets is created.

I had to define Scheduled task via Cloudwatch event via console, doing research in proper way to define it programatically.

- S3 bucket name is: [homework.itchy.cz](http://homework.itchy.cz.s3-website.eu-central-1.amazonaws.com), it's defined via [ansible declaration for production](src/prod)
- ECS cluster name is defined via [defaults/main.yml for deploy-to-aws role ](src/roles/deploy-to-aws/defaults/main.yml)
- Task have IAM role which allow it to push to S3 from ECS cluster.

#### Deployment to AWS from local machine
- ```docker run --env-file aws-credentials zrudko/homework:latest ansible-playbook deploy.yaml -i prod```
- provide env-file with your credentials such as, use filename *aws-credentials* ideally as it's contained in gitignore to mitigate hasty commits of plaintext credentials.
```bash
AWS_ACCESS_KEY_ID=NOT_BIG_SECRET
AWS_SECRET_ACCESS_KEY=SECRET
AWS_REGION=eu-central-1
```

### Service for updating dataset
Via running docker image [zrudko/homework:latest]((https://hub.docker.com/r/zrudko/homework)) we get dataset from COVID-19 [repo](https://github.com/CSSEGISandData/COVID-19) maintained by John Hopkins University. It is actually just ansible playbook role [update-dataset](src/roles/update-dataset/tasks/main.yml). Python + boto3 as lambda function would be better approach, but this was very quick and it's DSL approach. Plus I wanted to try way Fargate to runs containers. So Fargate pull and run ```zrudko/homework:latest```. That's it.

I did not add any logic for testing if URL to dataset filename with today's date yeald any HTTP 200. I just use shell date -1 day to get yesterday.

- Services without any arguments should exit 0 ```docker run zrudko/homework:latest``` after fulfilling purpose.
- It is meant to run as Fargate task which is triggered by cloudwatch event scheduler.
- AWS credentials to access S3 should be provided by IAM role once service is running as Fargate task.
- Dockerfile CMD is set to run ```ansible-playbook update-public-page.yaml -i prod```  which will get new dataset, parse it via read_csv module, push it to S3 archive and publish Czechia related data to S3 as HTML.
- Service is stupid. It's trying to get dataset from previous day. If fails, it should not change published html or archive. There is no error handling.

#### Run service from local machine
- provide docker run argument ```--env-file aws-credentials``` if you want to run service from your computer.

### Before going to production
- If dataset is in Github and owned by 3rd party, we should find good way to monitor repository updates. Maybe using github API for periodical checks and trigger updates based on it. Main issue with covid-19 repo is we are getting new datasets with delay because of -1 day hack while requesting dataset. Some simple method if dataset filename is not found, then try yesterday could be used. If data would be under our control, push based approach would be best.
- Switch from Fargate with Ansible to Lambda function. Run python function when repo is updated.
- Publish HTML via CloudFront to use HTTPS and enjoy caching (and deal with cache invalidations).
- Build and deployment should be handled by pipeline runner. Secrets should be provided to automation. For my projects I would go with Github actions and build pipelines there. If bitbucket I would go with their service.
- Test if playbook is able to provide cleanup of AWS resources.
- Provide tags for billing and inline tags with common resource definitions in operation.
- Make develop branch and run towards testing environment first. This would require to remove hardcoded CMD for prod group_vars from Dockerfile. I usually decide about target environment from branch name.
- Do monitoring of success/failure of tasks.

## Initial thoughts before starting work
Actualy best solution would be python+boto3 in lambda for getting URL and publishing to S3. But then there would be not much place for Ansible and not much place for dockerization. Maybe dockerization would be useful for keeping ansible deployment DSL and lambda function stuff in one place. But I have no experience with Fargate, so I wanted to do solve via Fargate.

*Update after playing with Ansible and Fargate. It's quite harder to deploy Fargate tasks via Ansible modules. Probably running CloudFormation via Ansible is better approach. Lambda would be definetely much faster deployment wise. Terraform would serve deployment better, but scheduled tasks has been as plugin in Terraform.*

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

## Homework definition

### Goal
Show the ability to automate the deployment of dockerized application Infrastructure and tools:

- AWS EC2 // **I used ECS + Fargate instead**
- AWS S3 // **Done**
- Docker and your preferred docker image // **Alpine for size**
- Ansible // **Done**
- Python or shell // **Just bit of shell as I did not prepared lambda function. If would I would use boto3 for S3 communication, check form some csv to dict library and render HTML somehow.**

### Task
1. Download regularly (e.g. daily / hourly) some dataset from the free data provider. If you down know any, choose from:
  - a. https://github.com/CSSEGISandData/COVID-19/ // **every 6 hours**
  - b. https://openweathermap.org/current
1. Store downloaded dataset to S3 bucket // **[S3 archive/covid-19/dataset-date.csv](https://s3.eu-central-1.amazonaws.com/homework.itchy.cz/archive/covid-19/05-06-2020.csv) has no directory index**
2. From every downloaded dataset, extract some specific data (eg data relevant for Czechia, Prague, ...) // **[Everytime jobs gets the URL, Czechia info is parsed and HTML updated](http://homework.itchy.cz.s3-website.eu-central-1.amazonaws.com)**
3. Display all extracted data using a single HTML page served from S3. A simple table is enough. // **[HTML, i keep only latest data ](http://homework.itchy.cz.s3-website.eu-central-1.amazonaws.com)**

### Instructions
- Use well-known languages (preferable Python 3 or shell) to create scripts/application // **Just bit of shell**
- Create a docker to encapsulate the application logic // **Done**
- Use latest Ansible to create roles and playbooks // **Done, if it's OK to consider latest by alpine package maintainers**
- Put all your source code in a public git repository (e.g. Github) // [github/westfood/homework:master](https://github.com/westfood/homework)
- Use Readme.MD file for the documentation (while evaluating we will use it to run the code) // **done**
- If you find problems, or not implement something, you should mention it there // **I did not used much of shell or Python - is it OK?**
- You don't need to provide automation for AWS infrastructure (EC2, S3) setup but you should document it // **WIP via deploy-to-aws role, S3 ready, working on handling fargate**

### Bonus points
- Replace EC2 with AWS serverless offering // **Does Fargate scheduled tasks counts as serverless?**
- Document the next steps to make this small app being ready for production // **should be there**
- Automate even the infrastructure setup (cloudformation, terraform) // **WIP via Ansible and shell**
- Create a CI / CD pipelines // **Just CD**
- Use your imagination and provide more than expected **Not much, let's say HTTPS should be served via Cloudfront, if page would be consumed heavily.**
