# Homework

## Goal
Show the ability to automate the deployment of dockerized application Infrastructure and tools:

- AWS EC2
- AWS S3
- Docker and your preferred docker image
- Ansible
- Python or shell

## Task
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
