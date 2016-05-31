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
  @USERS        = 'Users'

  ###
  @param server the express server or server url address
  ###
  constructor: (server, root, name)->
    return new RequestClient(server, root, name) unless this instanceof RequestClient
    @server = server
    root = url.get('restApiRoot') if isObject(root) and isFunc(root.get)
    if isString root
      @apiRoot = root
      root = path.join root, name if isString name
    else
      root = if isString(name) then name else ''
    @baseUrl = root

  request: (method, name, options)->
    url = (options and options.baseUrl) || @baseUrl
    url = path.join url, name.toString() if name
    accessToken = if options and options.accessToken then options.accessToken  else @accessToken
    result = request(@server)[method] url
    debug '%s %s accessToken:%s', method, url, accessToken
    debug options if options
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
      options.baseUrl = if @apiRoot then @apiRoot else RequestClient.API_ROOT
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
    # .query accessToken: @accessToken
    .expect 204
    .then (response)=>
      @accessToken = null
      response
