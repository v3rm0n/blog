---
layout: post
title: "Making public S3 buckets private"
tags: aws s3 infra
---

If you create a new S3 bucket in AWS it will not be publicly accessible by default, but this has not always
been the case. You might also have been serving public resources directly from an S3 bucket, but now you would like
to make the bucket private and serve the content through CloudFront instead. It's also a good idea
to [disable any and all public access][s3-block-account] to S3 buckets under an account by default so that mistakes when
creating new S3 buckets are harder to make. So what should you do if you would like to enable this control, but you have
some public S3 buckets under your account?

## What's the problem exactly?

Just make the S3 buckets private and problem solved? It might be that easy in a lot of cases, but what if you have
links to the files of the bucket out there? If you make your bucket private these links will break.
Problem is how can you know which files of the bucket are accessed publicly? You
enable [S3 Server Access Logs][s3-access-logs] of course. Now you have a trace of every file being accessed from your S3
bucket. It's cumbersome to parse those logs though, so you probably want to use [Athena][s3-access-athena] to query the
logs using SQL.

Now you can see what is accessed and when, but what you also want to know is how: you probably still need access
those files, just not publicly, so how do you know from access logs if the file is accessed publicly?
If you are also accessing the files using AWS SDKs then it's pretty easy: you look at the `sigv` column of the access
logs. If it has something like *SigV4* in it then the access is authenticated, if the column has *-* then it's a public
access.

So problem solved? Not really because if you want to serve the files using CloudFront then there is still no way to
differentiate between direct and through CloudFront access since CloudFront requests do not have a signature.

## Solution

There are probably multiple ways how to handle this issue, but what I came up with is adding
an [S3 Access point][s3-accesspoint] to the bucket and configuring the CloudFront distribution to use this endpoint
instead of direct bucket access. So how does this help exactly? If you check your access logs you can differentiate
between CloudFront and direct public access by looking at the `accesspointarn` column: when it has a value in it that is
not *-* then the request came through CloudFront.

Now you periodically check your access logs to find out which files are accessed directly (no signature in `sigv` and no
access point in `accesspointarn`) and try to fix the references until you are sure that there are no direct links left,
and you can continue to block all public access to all S3 buckets by default.

Of course, you can never be 100% sure that you have removed all the references, but if your end goal is to make the
bucket private then it's probably the best way to go and make the switch when you feel comfortable enough. If you know
any other solutions to this problem, let me know in the comments.

[s3-block-account]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/configuring-block-public-access-account.html

[s3-access-logs]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html

[s3-access-athena]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-s3-access-logs-to-identify-requests.html

[s3-accesspoint]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
