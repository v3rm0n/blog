---
layout: post
title: "Making public S3 buckets private"
tags: aws s3 infra
---

If you create new S3 buckets in AWS they will not be publicly accessible by default, but this has not always
been the case. You might also have been serving some public resources directly from an S3 bucket, but now you would like
to make the private and serve the content over CloudFront instead. It's also a good idea
to [disable any public access][s3-block-account] to S3 buckets under an account by default so that mistakes are harder
to make when creating new buckets. So what should you do if you would like to enable this control, but you have some
public S3 buckets on your account?

## What's the problem exactly?

So just make the S3 buckets private and problem solved? It might be that easy in a lot of cases, but what if you have
references to the files of the bucket out there? If you make your bucket private these links will break.
So how do you make sure what files of these buckets are accessed publicly? You
enable [S3 Server Access Logs][s3-access-logs] of course. Now you have a trace of every file being accessed from your S3
bucket. It's pretty hard to parse those logs though, so you probably want to use [Athena][s3-access-athena] to query the
logs.

Now you can see what is accessed and when, but what you also want to know is how: you probably still need access
those files just not publicly, so how do you know from access logs if it's a public access or not?
If you are accessing the files using AWS SDKs then it's pretty easy: you look at the `sigv` column of the access logs.
If it has something like *SigV4* in it then the access is authenticated, if the column has *-* then it's a public
access.

So problem solved? Not really because if you want to serve the files using CloudFront then there is still no way to
differentiate between direct and through CloudFront access since CloudFront requests do not have a signature.

## Solution

There's probably multiple ways how to handle this issue, but what I came up with is adding
an [S3 Accesspoint][s3-accesspoint] to the bucket and configured the CloudFront distribution to use this endpoint
instead of direct bucket access. So how does this help? Now if you check your access logs you can differentiate between
CloudFront and direct public access by looking at the `accesspointarn` column: when it has a value in it that is not *-*
then the request came through CloudFront.

Now you periodically check your access logs to find out which files are accessed directly and try to fix the references
until you are sure that there are no direct links left and you can block all public access to all S3 buckets by default.

Of course, you can never be 100% sure that you have removed all the references, but if your end goal is to make the
bucket private then it's probably the best way to go. If you know any other solutions to this problem, let me know in
the comments.

[s3-block-account]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/configuring-block-public-access-account.html

[s3-access-logs]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html

[s3-access-athena]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-s3-access-logs-to-identify-requests.html

[s3-accesspoint]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
