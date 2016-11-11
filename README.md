# nagios-check_s3_LastModified
Checks to see when an object in AWS S3 was last modified, and alerts based on thresholds you set.

Written in bash.

## Requirements
1. bash 3.0 or later
2. [jq](https://stedolan.github.io/jq/)
3. [aws cli](https://aws.amazon.com/cli/)
3. Credentials setup for aws cli, via IAM profile, or config files.
    See [Configuring the AWS Command Line Interface](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

## Usage
    -b BUCKET -k OBJECT -w warning_age -c critical_age [-d ]
      -b BUCKET: name of the S3 bucket"
      -k OBJECT: full path to the S3 key/object/file
      -w and -c:  values in seconds
      [-d] : show debug output
