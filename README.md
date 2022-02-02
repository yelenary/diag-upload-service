Diag Upload Service
===================================

Application listen on HTTPS (signed with self signed SSL).

The URL is https://diag-alb-703602959.us-west-2.elb.amazonaws.com

Opening this link in the browser will be blocked and generate "This connection is not Private" error.

You will have to accept a self signed certificate and add the .cert certificate into you certificate chain on your local computer.

Alternatively curl can be used to access the service as follow:

      curl -k https://diag-alb-703602959.us-west-2.elb.amazonaws.com
      Output: File text.tgz uploaded%

      curl -F 'diag=@test555.txt' -k https://diag-alb-703602959.us-west-2.elb.amazonaws.com/upload
      Output: Not compatible diag file format provided. *.tgz file required.%


P.S: In the real production environment SSL certificate can be issues by Amazon certificate manager and verified by the DNS provider (Route53 for example)

Self signed SSL certs to secure the service:
======================================
The application is secured with free self signed SSL certificate.
The certs were issued as follow:
Issues self signed certs:

      openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt
      
Verify the keys:

      openssl rsa -in privateKey.key -check
      
Convert the key and cert into .pem encoded file

      openssl rsa -in privateKey.key -text > private.pem
      openssl x509 -inform PEM -in certificate.crt > public.pem
      
Upload the Certificate using AWS IAM CLI

aws iam upload-server-certificate --server-certificate-name DIAG --certificate-body file://public.pem --private-key file://private.pem --profile diag
{
    "ServerCertificateMetadata": {
        "Path": "/",
        "ServerCertificateName": "DIAG",
        "ServerCertificateId": "ASCA42DDV452T7LP7OM7M",
        "Arn": "arn:aws:iam::880677349237:server-certificate/DIAG",
        "UploadDate": "2022-02-02T05:43:03+00:00",
        "Expiration": "2023-02-02T05:30:56+00:00"
    }
}

arn of the certificate has be assigned to the listener on the Application load balancer (see main.tf line 64)




Install and run application locally (Mac platform)
===================================================
1. Make sure node js is installed (brew install node)
2 From the directory containing your app files execute:
   npm install
   node index.js
Output: App is listening on port 8000!

3. The application is now serving requests on port 8000 of your localhost.

Basic local test:

      curl localhost:8000
       Diag Service%
  
      curl -F 'diag=@test.txt' localhost:8000/upload
      File test.txt uploaded
  
P.S make sure to create diags directory at your working directory - otherwise the app exit with ERR_HTTP_HEADERS_SENT exception.


Dockerized application install instructions:
===============================================
Build and push the image to local docker registry:

      docker build . -t diaguploadtest
      docker push diaguploadtest
      
Map port 80 on the localhost to port 8000 of the container

      docker run -p 80:8000 diaguploadtest
      
Make sure the app is running:

      curl localhost
      Diag Service%

      curl -F 'diag=@text.tgz' localhost/upload
      File text.tgz uploaded%



Core service components:
======================================

  **Github Actions as CI/CD
  
  **Infrastructure setup with Terraform on AWS
  
  **Fargate ECS as a platform


  CI/CD workflow.
  ======================================
  The idea of the workflow is execute on every commit related to the main branch, and to deploy it every time a new tag is pushed (
  Note: Improvement required: 
       - tag is constant (latest) right now for the simplicity but it should be attached to github reference or image version.
       - Currently it executes on every push to master instead triggering on the tag only.

  The repository leverages Github Actions as CI/CD tool.
  The workflow is as follow:
  - Check out the repo
  - Configure AWS credentials
  - Login to Amazon ECR
  - Build, tag, and push image to private Amazon ECR
  - Download task definition
  - Fill in the new image ID in the Amazon ECS task definition
  - Deploy Amazon ECS task definition

  CI/CD setup utilize github secrets - see example
  
      lryazano@LRYAZANO-M-92CU terraform % gh secret set AWS_ACCESS_KEY_ID -b $(terraform output publisher_access_key)
       ✓ Set secret AWS_ACCESS_KEY_ID for yelenary/diag-upload-service

       List of gh secrets:
       lryazano@LRYAZANO-M-92CU terraform % gh secret list
       AWS_ACCESS_KEY_ID      Updated 2022-01-30
       AWS_REGION             Updated 2022-01-30
       AWS_SECRET_ACCESS_KEY  Updated 2022-01-30
       ECR_REPOSITORY_NAME    Updated 2022-01-30
       ECS_CLUSTER            Updated 2022-01-30
       ECS_SERVICE            Updated 2022-01-30


  Cloud infrastructure deployed with Terraform plan.
  Terraform deployment files can be found in the */terraform folder.
  The following components are deployed:

  **ALB, basic networking, service ingress/egress rules (main.tf)**
  **ECS Cluster and  ECS Service with logs configuration using awslogs logdriver (ecs.tf)**  
  **ECR Container Registry (ecr.tf)**  
  **IAM user and policy (iam.tf)**  
  **S3 bucket as a backend to store the .tfstate (backend.tf)**  
  **Input/output variables (variables.tf, output.tf)**  
  
  Minimum required version for AWS provider is 0.12




  Service Observability
  ======================================
  There multiple possible platform available to configure observability tools for the services running on ECS (i.e Datadog, Retrace, Prometheus metrics)
  AWS CloudWatch Container Insights has been selected as a solution mainly due to simplicity.

  Observability dahsboard URL:  https://us-west-2.console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=Diag-service-observability-daashboard

  To enable Container Insights on an existing ECS cluster, you have to use the CLI (it’s not possible to do this via the ECS console).
  The sample code below shows how you would use the update-cluster-settings command to enable Container Insights on an ECS cluster named diag-ecs:

    aws ecs update-cluster-settings --cluster diag-ecs --settings name=containerInsights,value=enabled --region your_region --profile your_ptofile

  Check if Container Insights settings enabled:

    aws ecs describe-clusters --clusters diag-ecs --region your_region --profile your_ptofile --include SETTINGS

  Enable Logs for better insight into ECS and service utilization and performance:
  For ECS Fargate the supported log drivers are awslogs, splunk, and awsfirelens
  Current solution utilize  awslogs log driver and added as required logConfiguration parameter to the ECS task definition



  Diag service Enhancements:
  ======================================
  
  a. Accept only ".tgz" files - performed by checking the existence of ".tgz" string inside provided file name (indexOf() function) and checking that .tgz are     last 4 charachters of the file name.
  
  b. For the authentication - ALB Authentication works by defining an authentication action in a listener rule.
  The ALB’s authentication action  check if a session cookie exists on incoming requests, then check that it’s valid. If the session cookie is set and valid then   the ALB will route the request to the target group with X-AMZN-OIDC-* headers set. The headers contain identity information in JSON Web Token (JWT) format,    that a backend can use to identify a user. If the session cookie is not set or invalid then ALB will follow the OIDC protocol and issue an HTTP 302 redirect to the identity provider.
  Attempted to setup authentication with Auth0 following this article:
  https://medium.com/@sandrinodm/securing-your-applications-with-aws-alb-built-in-authentication-and-auth0-310ad84c8595
  However after configuring required authentication rules  for the HTTPS listener in the ALB and accessig the application I'm receiving  414 request-uri too   large. Seems like the reason is that Application load balancer has a limit on the length of HTTP Header.
  
  This problem could be solved replacing Application load balancer with NLB (NLB don't have a limit for HTTP header. this is not implemented due to the time constraint)

  c. Automatic scaling -  ability to increase or decrease the desired count of tasks in your  ECS Fargate service automatically.
  Re-configure service and add autoscaling policy.
  Used  CloudWatch metrics to scale  out the service (i.e to add tasks) to deal with high demand at peak times,
  and to scale in your service (run fewer tasks) to reduce costs during periods of low utilization.
  For this assignment I used CPUUtilization to setup CloudWatch alarms (but any other metric can be used)
  two Cloudwatch alarms were created:
    ECSServiceScaleOutAlarm (scale out diag service when the CPU utilization is greater then 75%)
    ECSServiceScaleInAlarm  (scale in diag service when the CPU utilizationif is lower then 25%)
