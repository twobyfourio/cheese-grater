AWS    = require 'aws-sdk'
FS     = require 'fs'
GitHub = require 'github'
Git    = require 'git'

decrypt = (filename, success)->
  encryptedConfiguration =
    CiphertextBlob: FS.readFileSync(filename)

  new AWS.KMS().decrypt encryptedConfiguration, (err, decryptedPayload)->
    return this.fail('decryption failed') if err
    success decryptedPayload

exports.handler (event, context)->
  decrypt.bind(context).apply './config.enc', (config)->
    do(github = new GitHub(version: '3.0.0'))->
      config.payload.name        = event.name || event.text.split(' ')[0]
      config.payload.description = event.description || event.text.slice(event.text.indexOf(' '))
      
      github.authenticate config.authentication
      github.repos.createFromOrg payload, (err, response)->
        context[err ? 'fail' : 'succeed'].apply null, err

