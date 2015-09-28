chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'blog_reminder:', ->
  blog_reminder_module = require('../src/blog-reminder')

  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()
    @msg =
      send: sinon.spy()
      random: sinon.spy()
    @blog_reminder_module = blog_reminder_module(@robot)

  describe 'record a comment', ->

    # TODO
