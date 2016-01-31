AWS = require 'aws-sdk'
FS  = require 'fs'

exports.handler (event, context)->
  encryptedCommandConfig =
    CipherTextBlob: JSON.parse FS.readFileSync './commands.json.enc'

  new AWS.KMS().decrypt encryptedCommandConfig, (err, commands)->
    return context.fail('decryption failed') if err

    for key, values of (commands[event.command] || commands.default)
      unless event[key] in values
        return context.fail("#{key} : #{event[key]} failed")

   topicPayload =
      Name: String(commands.prefix) + event.command.slice(1)

    # Idempotency is our friend
    new AWS.SNS().createTopic topicPayload, (err, data)->
      message =
        Message: JSON.stringify event
        TopicArn: data['TopicArn']

      new AWS.SNS().publish message, (err)->
        context[err ? 'succeed' : 'fail'](err)
