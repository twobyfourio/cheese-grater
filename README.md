# cheese-grater

I'm very much a fan of monolithic architectures, mostly under the philosophy of avoiding premature optimizations, but I am under no inclination to inflict upon myself pain that could be avoided with a few cleverly crafted lines of code spooled up on their own process. (Microservices?)

[AWS Lambda](https://aws.amazon.com/lambda/) has solved the pain and potential expense of hosting many microservices, but writing code and configuring runtimes in a GUI is painful and lacked the visibility of a nice `git log` and a `#monitor-github` channel. And, of course, support for multiple files.

So cheese-grater lets me generate, configure, and deploy a Lambda function in no time, all from the comfort of VIM and CoffeeScript. (Why cheese-grater? Start grating shreds off of your monolithic block of cheese... I know, it's awful.)

## Encryption

Managing secrets in Lambda functions manually is also tedious, and cheese-grater invests a bit of work upfront to make this much easier to handle. There are two parts to cheese-grater's encryption helpers:

* **Deployment:** You can inspect this in Rakefile. All files in `functions/function-name` except `run.coffee` and `config.yml` will be encrypted using Amazon's Key Management Service before being added to the ZIP deployment package. We can then easily decrypt any additional files we need in our Lambda function at runtime. Note that a helper function is included to make this simple, check out the examples.

* **Code storage/GitHub:** Any files within `functions/(function-name)/` that are git-ignored will be encrypted and the resulting `$FILE.enc` and `$FILE.key` files added to the repository. (This happens in your git `pre-commit` hook, so be sure to run `bin/setup` to symlink the hooks into your local git repository.) On the reverse side, when you pull down changes, any encrypted files will be decrypted back for your local development efforts.

## TL;DR

* `bin/setup` to set up your git hooks
* `rake stub NAME=example` to stub out `functions/example/` 
* `rake test` to check that your coffeescript files compile
* `rake build` to build your deployment zips
* `rake` to compile, build, and upload your Lambda functions

## Examples

Check out the `examples/` directory for specific functions we are using, and 

## Overriding default configurations

Certain values, like `timeout` or `memory`, might need to be tweaked for specific Lambda functions. You can easily adjust these in the `config.yml` file within each function.

## Slack slash commands

If you have any Lambda functions you want to run using slash commands within Slack, a few moments with the [AWS API Gateway](https://aws.amazon.com/api-gateway/) will get you set up.

## Known bugs and issues

* You'll need to set up an AWS KMS key for your AWS user. We can make this easier.
* You'll need to add an IAM Role and specify the role ARN in the Rakefile. We can automate this, for sure.

## Future improvements

* Add Python and Java support
* I'd love if you could also configure API Gateway from the config.yml files, and I think this would be fairly straightforward.
* More immediately useful will be configuring the [Amazon SNS](https://aws.amazon.com/sns/) topics a Lambda function subscribes to from the `config.yml`. This is a very common pattern for me.

## Authored

&copy; 2016 2by4io llc. Built with :heart: & :coffee: in Austin, Texas. 

