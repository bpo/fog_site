# fog_site #

*fog_site* is a simple utility gem for deploying a static site to Amazon S3 and
CloudFront using the *fog* gem.

To make deployments fast, this gem calculates the MD5 sum of every file locally
and compares them against the information stored on S3 (in the 'etag' property
of the S3 object). Files are only uploaded if the etag has changed.

## Usage ##

Create a new site

    site = FogSite.new "www.stovepipeapp.com"

Decide what you want to deploy

    site.path = "/home/bpo/stovepipe"

Decide whether to destroy resources that aren't local

    site.destroy_old_files = true

If you're using CloudFront, specify a distribution ID:

    site.distribution_id = "Z99120CAFEBABE"

You can set headers on a global level

    site.headers = { 'Expires' => '0' }

And push it to the cloud

    site.deploy!

All local settings for a site can be passed into the `new_site` method:

    FogSite.new "stovepipeapp.com", :path => "/home/bpo/stovepipe",
                                             :destroy_old_files => true

AWS credentials are read from the environment variables `AWSAccessKeyId` and
`AWSSecretKey`, but can also be set programmatically:

    site = FogSite.new "stovepipeapp.com"
    site.access_key_id = "E7L8CCM59BFXJOAMEAPT"
    site.secret_key = "t5nszajv3y8u4zI/LtP/r5xUmPnqAT/Tv2n7Xr7n"

## Notes ##

### Usage ###

We use this tool internally at [Stovepipe Studios](http://www.stovepipestudios.com/)
to manage our static domain deployments. We have a simple Rake script with a
task for each of our different sites - each task builds a FogSite and has the
configuration variables set according to that site's needs.

### Choice of Domains ###
DNSimple offers a [custom ALIAS record type](http://blog.dnsimple.com/zone-apex-naked-domain-alias-that-works/)
that can be used for apex domains (e.g. foo.com rather than www.foo.com).
Or you can set up a lightweight server that accepts requests
for foo.com and redirects to the correct target.

### Cloudfront Cache Invalidation ###

This gem uses cache invalidation to force new content to be refreshed by
CloudFront distributions. This works just fine, but if your content changes
often, it's better (and cheaper) to use versioning. See the CloudFront developer
guide for details on how to implement a versioning system.

### See also ###

* http://gun8.com/a-fun-little-workflow-for-developing-static-sites - blog post
  featuring fog_site.

## Copyright ##

Copyright (c) 2013 Brian P O'Rourke. See LICENSE.txt for
further details.
