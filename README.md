# incubator-nuttx-testing

Tools and configuration for NuttX testing.

## Jenkins pipeline shared library

The repository root contains the structure needed for a [Jenkins pipeline shared library](https://jenkins.io/doc/book/pipeline/shared-libraries/) to define the continuous integration pipeline outside of the [main NuttX repository](https://github.com/maht/incubator-nuttx). To be used from the main repo the following Jenkinsfile has to be defined:

```groovy
@Library('incubator-nuttx-testing') _

runContinuousIntegrationPipeline()
```

## Jenkins multibranch pipeline job creation/update

The repository contains a definition of a multibranch pipeline job called 'incubator-nuttx' and some scripts to create and update it.

Copy the `setup-example.sh` to `setup.sh` and edit proper values inside for Jenkins user, password and URL.

Then source it with '. setup.sh' and execute 'jobs/incubator-nuttx/create.sh' or 'jobs/incubator-nuttx/update.sh' to create/update the multibranch pipepline job.
