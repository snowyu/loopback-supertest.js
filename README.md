# Loopback Supertest


### Installation

1. Install in you loopback project:

```bash
npm install --save-dev supertest, supertest-as-promised, loopback-supertest
```



### Usage

```coffee
app     = require '../server/test-app'
Api     = require 'loopback-supertest'

describe "Accounts", ->

  server = null
  accounts = null

  before (done)->
    app.start (err, result)->
      server = result unless err
      accounts = Api server, app, 'Accounts'
      done(err)

  after (done)->
    server.close(done) if server

  it "should create a new account", ->
    accounts.post(username: 'jack', password:'xxx', email:'xxx@xx.com')
    .expect 200
  it "should login a account", ->
    accounts.login username: 'jack', password:'xxx'

```


`test-app.js`:

```js
process.env.NODE_ENV = 'test' //TODO: BUG change to everything could not work!!

require('coffee-script/register');
require('require-yaml');

var path        = require('path');
var loopback    = require('loopback');
var boot        = require('loopback-boot');
var autoMigrate = require('./common/auto-migrate-data');

var app = module.exports = loopback();

app.start = function(done) {
  // Bootstrap the application, configure models, datasources and middleware.
  // Sub-apps like REST API are mounted via boot scripts.
  boot(app, __dirname, function(err) {
    if (err) throw err;
    var defaultFixtureFolder = path.resolve(__dirname, './data');
    autoMigrate(app, defaultFixtureFolder).then(function(){
      console.log('autoMigrate successful')
      // start the web server
      var server = app.listen(function(err) {
        app.emit('started');
        if (done) done(err, server)
      });
    })
    .catch(function(err){done(err)});

  });
};
```
