_ = require('lodash')
Promise = require('bluebird')
capitano = Promise.promisifyAll(require('capitano'))
umount = Promise.promisifyAll(require('umount'))
visuals = require('resin-cli-visuals')
config = require('resin-config-json')
prettyjson = require('prettyjson')

exports.read =
	signature: 'config read'
	description: 'read a device configuration'
	help: '''
		Use this command to read the config.json file from a provisioned device

		Examples:

			$ resin config read --type raspberry-pi
			$ resin config read --type raspberry-pi --drive /dev/disk2
	'''
	options: [
		{
			signature: 'type'
			description: 'device type'
			parameter: 'type'
			alias: 't'
			required: 'You have to specify a device type'
		}
		{
			signature: 'drive'
			description: 'drive'
			parameter: 'drive'
			alias: 'd'
		}
	]
	permission: 'user'
	root: true
	action: (params, options, done) ->
		Promise.try ->
			return options.drive or visuals.drive('Select the device drive')
		.tap(umount.umountAsync)
		.then (drive) ->
			return config.read(drive, options.type)
		.tap (configJSON) ->
			console.info(prettyjson.render(configJSON))
		.nodeify(done)

exports.write =
	signature: 'config write <key> <value>'
	description: 'write a device configuration'
	help: '''
		Use this command to write the config.json file of a provisioned device

		Examples:

			$ resin config write --type raspberry-pi username johndoe
			$ resin config write --type raspberry-pi --drive /dev/disk2 username johndoe
			$ resin config write --type raspberry-pi files.network/settings "..."
	'''
	options: [
		{
			signature: 'type'
			description: 'device type'
			parameter: 'type'
			alias: 't'
			required: 'You have to specify a device type'
		}
		{
			signature: 'drive'
			description: 'drive'
			parameter: 'drive'
			alias: 'd'
		}
	]
	permission: 'user'
	root: true
	action: (params, options, done) ->
		Promise.try ->
			return options.drive or visuals.drive('Select the device drive')
		.tap(umount.umountAsync)
		.then (drive) ->
			config.read(drive, options.type).then (configJSON) ->
				console.info("Setting #{params.key} to #{params.value}")
				_.set(configJSON, params.key, params.value)
				return configJSON
			.tap ->
				return umount.umountAsync(drive)
			.then (configJSON) ->
				return config.write(drive, options.type, configJSON)
		.tap ->
			console.info('Done')
		.nodeify(done)

exports.reconfigure =
	signature: 'config reconfigure'
	description: 'reconfigure a provisioned device'
	help: '''
		Use this command to reconfigure a provisioned device

		Examples:

			$ resin config reconfigure --type raspberry-pi
			$ resin config reconfigure --type raspberry-pi --advanced
			$ resin config reconfigure --type raspberry-pi --drive /dev/disk2
	'''
	options: [
		{
			signature: 'type'
			description: 'device type'
			parameter: 'type'
			alias: 't'
			required: 'You have to specify a device type'
		}
		{
			signature: 'drive'
			description: 'drive'
			parameter: 'drive'
			alias: 'd'
		}
		{
			signature: 'advanced'
			description: 'show advanced commands'
			boolean: true
			alias: 'v'
		}
	]
	permission: 'user'
	root: true
	action: (params, options, done) ->
		Promise.try ->
			return options.drive or visuals.drive('Select the device drive')
		.tap(umount.umountAsync)
		.then (drive) ->
			config.read(drive, options.type).get('uuid')
				.tap ->
					umount.umountAsync(drive)
				.then (uuid) ->
					configureCommand = "os configure #{drive} #{uuid}"
					if options.advanced
						configureCommand += ' --advanced'
					return capitano.runAsync(configureCommand)
		.then ->
			console.info('Done')
		.nodeify(done)
