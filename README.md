# sample-deployment-service

This repository shows how kapstan can be used to enhance developer experience while retaining the ability to use customized private helm charts.

To use kapstan for private helm charts, devops or admin will add a `kapstan.yaml` file in same folder where `Chart.yaml` is present.
This file tells kapstan which variables to use, and how they should be rendered.

There are two ways any helm chart can be used within kapstan plaform.

## As standalone service
This is useful when every helm chart is for a different service and there are no or very few common configurations.
Example for this is within `sample-service` folder.


## As template
This is useful when we want to create multiple different services using same helm chart but different values. 

For example, there could be multiple services that all expose grpc endpoint and save/retrieve data from database. 
Instead of adding separate helm chart for each service, we could add a single helm chart and provide database details and grpc details in values file.

Example for this is within `sample-template` folder.