# incubator-nuttx-testing

Tools and configuration for NuttX testing.

## Jenkins pipeline shared library

The repository root contains the structure needed for a [Jenkins pipeline shared library](https://jenkins.io/doc/book/pipeline/shared-libraries/) to define the continuous integration pipeline outside of the [main NuttX repository](https://github.com/maht/incubator-nuttx). To be used from the main repo the following Jenkinsfile has to be defined:

```groovy
@Library('incubator-nuttx-testing') _

runContinuousIntegrationPipeline()
```
