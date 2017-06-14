# cfn-catalog-test
Test deploying and maintaining CloudFormation templates as AWS Service Catalog products

### Token Replacement

The Makefile replaces the several token values in the template to track versioning and
object location within S3

### Deployment to S3

To allow templates to be updated without breaking existing deployments the Makefile creates
S3 key names based on the output of the [git describe](https://git-scm.com/docs/git-describe#_examples)
command. Releases have to be tagged and will also be copied to a "latest" key for users who
don't wish to use a versioned key name.

```
s3-bucket/
└── cfn-catalog-test
    ├── dev
    │   ├── v0.7-1-gef2f742
    │   └── v0.7-dirty
    ├── latest
    ├── v0.6
    └── v0.7
```
