debug   = require('debug')('superagent')
request = require 'supertest-as-promised'
path    = require 'path.js/lib/posix'
isString= require 'util-ex/lib/is/type/string'
isObject= require 'util-ex/lib/is/type/object'
isFunc  = require 'util-ex/lib/is/type/function'

###
# export DEBUG=superagent
# to print the request debug info
RequestClient = require './request-client'

server = app.listen (err)->
  throw err if err
  client = RequestClient(server, '/api', 'Accounts')
  client.login username:'jack', password: 'xxx'
  .then ->
    client.getUser username: 'jack'
  .then (response)->
###
module.exports  = class RequestClient
  @API_ROOT     = '/api/'
  @USERS        = 'Users'

  ###
  @param server the express server or server url address
  ###
  constructor: (server, url, name)->
    return new RequestClient(server, url, name) unless this instanceof RequestClient
    @server = server
    if isFunc url.get
      @app = url
      url  = url.get 'restApiRoot'
    if isString url
      url = path.join url, name if isString name
      @baseUrl = url

  request: (method, name, options)->
    url = (options and options.baseUrl) || @baseUrl
    url = path.join url, name.toString() if name
    accessToken = if options and options.accessToken then options.accessToken  else @accessToken
    result = request(@server)[method] url
    debug '%s %s accessToken:%s', method, url, accessToken
    result.set 'Authorization', accessToken if accessToken
    result
  get: (name, options)->
    @request 'get', name, options
  post: (name, options)->
    if isObject name
      options = name
      name = null
    result = @request 'post', name, options
    result.send options.data if options and options.data
    result
  put: (name, options)->
    if isObject name
      options = name
      name = null
    result = @request 'put', name, options
    result.send options.data if options and options.data
    result
  del: (name, options)->
    @request 'delete', name, options
  delete: @::del
  head: (name, options)->
    @request 'head', name, options

  _getUserOptions: (options)->
    options = {} unless options
    unless options.baseUrl
      options.baseUrl = if @app then @app.get 'restApiRoot' else RequestClient.API_ROOT
      options.baseUrl = path.join options.baseUrl, RequestClient.USERS
    options
  login: (user, options)->
    options = @_getUserOptions options
    @request 'post', 'login', options
    .send user
    .expect 200
    .then (response)=>
      @accessToken = response.body.id if response.body.id
      response
  logout: (options)->
    options = @_getUserOptions options
    @request 'post', 'logout', options
    .expect 204
    .then (response)=>
      @accessToken = null
      response
