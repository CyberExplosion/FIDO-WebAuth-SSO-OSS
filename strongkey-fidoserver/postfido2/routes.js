/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */
// import dateFormat from 'dateformat'
// import fs from 'fs'
// import crypto from 'crypto'
// import url from 'url'
// import express from 'express'
// import session from 'express-session'
// import sqlite from 'sqlite'
import dateFormat from 'dateformat';
import { appendFile } from 'fs';
import crypto from 'crypto';
import { fileReader as _fileReader } from './fileReader.js';
import url from 'url';
import { Router, static as expressStatic } from 'express';
import session from 'express-session';
import sqlite3 from 'sqlite3';
var router = Router();
const sqlite = sqlite3.verbose()
router.use(expressStatic('public'));

// LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
// Add a 'const https = require('https');' This is what is used to make http requests
// to the FIDO2 server.
// Add 'const CONSTANTS = require('./constants');'.
// import https from 'https'
// import CONSTANTS from 'constants'
// import useragent from 'express-useragent'
import { request } from 'https';
import { SVCINFO, SKFS_HOSTNAME, SKFS_PORT, SKFS_PREAUTHENTICATE_PATH, SKFS_PREREGISTRATION_PATH, METADATA_VERSION, METADATA_LOCATION, SKFS_AUTHENTICATE_PATH, SKFS_REGISTRATION_PATH, SKFS_GET_KEYS_INFO_PATH, SKFS_DEREGISTER_PATH } from './constants.mjs';
import { express as _express } from 'express-useragent';
router.use(_express());
// LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL



let failedRegistration = null;


//Template routes

//route for dashboard.html
router.get('/dashboard', (req, res) => {
  log(req.session.userid);
  //Checking if user is logged in
  if (req.session.userid) {
    _fileReader("/dashboard.html", "text/html", req, res);
  } else {
    res.redirect("/login");
  }

});
//route for login.html
router.get('/login', (req, res) => {
  _fileReader("/login.html", "text/html", req, res);
});
//route for register.html
router.get('/register', (req, res) => {
  req.session.failedReg = false;
  //checks if registration failed on last request to show failed to register
  //message
  if (failedRegistration) {
    req.session.failedReg = true;
  }
  _fileReader("/register.html", "text/html", req, res);
  failedRegistration = false;
});


//Database routes

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// Replace the /loginSubmit and /registerSubmit post listeners with /getChallenge
// and /submitChallengeResponse listeners. The purpose of the /getChallenge listener
// is the receive the necessary data from the APPCLIENT and make the appropriate request
// to the FIDO2SERVER. This request returns a challenge that is then passed on to the
// APPCLIENT to be used in interacting with the FIDO2 authenticator. It checks whether
// or not the user exits in the APPSERVER database before making before running the
// request or not running the request to the FIDO2SERVER (depending on intent). The
// purpose of the /submitChallengeResponse listener is to receive the response given
// by the FIDO2 authenticator sent by the APPCLIENT and send it to the FIDO2SERVER
// through the appropriate post request. Upon receiving a successful response from
// the FIDO2SERVER, result is  sent to the APPCLIENT as the post response. If the
// intent is registration, the user’s credentials are saved in the APPSERVER database.


//login user upon login submit
router.post("/getChallenge", (req, res) => {
  console.log('Does it get here')
  var intent = req.body.intent;
  var username = req.session.username = req.body.username;
  if (intent == "authentication") {
    if (username == "") {
      res.redirect("/login");
      return;
    }
    var db = getDB();
    db.get(`select * from users where username = ? `, [username],
      (err, row) => {
        if (err) {
          log("ERROR: " + err.message);
        }
        if (row) {
          req.session.possibleuserid = row.id;
          process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;
          const data = JSON.stringify({
            svcinfo: SVCINFO,
            payload: {
              username: username,
              options: {}
            }
          });
          const options = {
            hostname: SKFS_HOSTNAME,
            port: SKFS_PORT,
            path: SKFS_PREAUTHENTICATE_PATH,
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            }
          };
          const fido2Req = request(options, fido2Res => {
            log(`statusCode: ${fido2Res.statusCode}`);

            fido2Res.on('data', d => {
              log("challengeBuffer=");
              log(d);
              res.json({ Response: d.toString() });
            })
          });
          fido2Req.on('error', error => {
            log(error);
            res.json({ Response: "skfs-error" });
          });
          fido2Req.write(data);
          fido2Req.end();
        } else {
          res.json({ Response: "sqlite-error" });
        }
      });
  } else if (intent == "registration") {
    console.log('Get to registration')
    var firstname = req.session.firstname = req.body.firstname;
    var lastname = req.session.lastname = req.body.lastname;
    var displayname = req.session.displayname = req.body.displayname;
    if (username == "" | displayname == "" | firstname == "" | lastname == "") {
      console.log('it doesnt do anyhting')
      res.redirect("/register");
      return;
    }
    var db = getDB();
    console.log('it get through the db line')
    db.get(`select * from users where username = ? `, [username],
      (err, row) => {
        if (err) {
          log("ERROR: " + err.message);
        }
        if (!row) {

          process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;
          const data = JSON.stringify({
            svcinfo: SVCINFO,
            payload: {
              username: username,
              displayname: displayname,
              options: { "attestation": "direct" },
              extensions: "{}"
            }
          });
          const options = {
            hostname: SKFS_HOSTNAME,
            port: SKFS_PORT,
            path: SKFS_PREREGISTRATION_PATH,
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            }
          };
          const fido2Req = request(options, fido2Res => {
            log(`statusCode: ${fido2Res.statusCode}`);

            fido2Res.on('data', d => {
              log("challengeBuffer=");
              log(d);
              res.json({ Response: d.toString() });
            })
          });
          fido2Req.on('error', error => {
            log(error);
            res.json({ Response: "skfs-error" });
          });
          fido2Req.write(data);
          fido2Req.end();
        } else {
          failedRegistration = true;
          res.json({ Response: "sqlite-error" });
        }
      });
  }
});
router.post("/submitChallengeResponse", (req, res) => {
  var intent = req.body.intent;
  var username = req.session.username;
  var credResponse = req.body;
  var reqOrigin = req.get('host');

  let data = "";
  let path = "";
  if (intent == "authentication") {
    var metadataJSON = {
      version: METADATA_VERSION,
      last_used_location: METADATA_LOCATION,
      username: username,
      origin: "https://" + reqOrigin,
      clientUserAgent: req.useragent.source
    };
    var responseJSON = {
      id: credResponse.id,
      rawId: credResponse.rawId,
      response: {
        authenticatorData: credResponse.authenticatorData,
        signature: credResponse.signature,
        userHandle: credResponse.userHandle,
        clientDataJSON: credResponse.clientDataJSON
      },
      type: "public-key"
    };
    data = JSON.stringify({
      svcinfo: SVCINFO,
      payload: {
        strongkeyMetadata: metadataJSON,
        publicKeyCredential: responseJSON,
      }
    });
    path = SKFS_AUTHENTICATE_PATH;
  } else if (intent == "registration") {
    var firstname = req.session.firstname;
    var lastname = req.session.lastname;
    var db = getDB();
    var metadataJSON = {
      version: METADATA_VERSION,
      create_location: METADATA_LOCATION,
      username: username,
      origin: "https://" + reqOrigin
    };

    var responseJSON = {
      id: credResponse.id,
      rawId: credResponse.rawId,
      response: {
        attestationObject: credResponse.attestationObject,
        clientDataJSON: credResponse.clientDataJSON
      },
      type: "public-key"
    };

    data = JSON.stringify({
      svcinfo: SVCINFO,
      payload: {
        strongkeyMetadata: metadataJSON,
        publicKeyCredential: responseJSON,
      }
    });
    path = SKFS_REGISTRATION_PATH;
  }
  const options = {
    hostname: SKFS_HOSTNAME,
    port: SKFS_PORT,
    path: path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const fido2Req = request(options, fido2Res => {
    log(`statusCode: ${fido2Res.statusCode}`);

    fido2Res.on('data', d => {
      if (d.toString().toLowerCase().includes("error")) {
        res.json({ Response: d.toString() });
        return;
      }
      if (intent == "registration") {
        db.run('insert into users(username,first_name,last_name) values(?,?,?)', [username, firstname, lastname], function (err) {
          if (err) { log("ERROR: " + err.message); }
          log("user added: \nfirst name: " + firstname + "\nlast name: " + lastname + "\nusername: " + username);
          req.session.justReg = true;
          log(d);
          res.json({ Response: d.toString() });
        });
      } else if (intent == "authentication") {
        req.session.userid = req.session.possibleuserid;
        log(d);
        res.json({ Response: d.toString() });
      }
    })

  });

  fido2Req.on('error', error => {
    log(error);
    res.json({ Response: "error" });
  });
  process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;
  fido2Req.write(data);
  fido2Req.end();
});

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

//add a quote
router.post("/addQuote", (req, res) => {
  var id = req.session.userid;
  var name = req.body.name;
  var now = new Date();
  var date = dateFormat(now, "ddd mmm dd yyyy HH:MM:ss Z");
  var filepath = req.body.filepath;
  var db = getDB();
  //checking if quote is already in database
  db.get(`select * from quotes where name = ? or filepath = ? `, [name, filepath],
    (err, row) => {
      if (err) {
        log("ERROR: " + err.message);
      }
      if (!row) {
        //adding quote to database
        db.run('insert into quotes(uploader,name,date,filepath) values(?,?,?,?)', [id, name, date, filepath], function (err) {
          if (err) { log("ERROR: " + err.message); }
          log("quote added: name: " + name + "\nuploader: " + id + "\nfilepath: " + filepath);
          res.redirect("/dashboard");
        });
      } else {
        res.redirect("/dashboard");
      }
    });
});

//logging out current user
router.get("/logout", (req, res) => {
  log(req.session.userid + " signed out");
  req.session.userid = null;
  res.redirect("/login");
});
//getting username from database
router.post("/getUsername", (req, res) => {
  var db = getDB();
  var id = req.session.userid;

  db.get(`select username from users where id = ? `, [id],
    (err, row) => {
      if (err) {
        log("ERROR: " + err.message);
      }
      res.json({ userData: row });
    });
});
//get quotes based on currently signed in uploader
router.post("/getQuotes", (req, res) => {
  var db = getDB();
  var id = req.session.userid;

  db.all(`select * from quotes where uploader = ? `, [id],
    (err, row) => {
      if (err) {
        log("ERROR: " + err.message);
      }
      res.json({ quotes: row });
    });
});
//get all quotes from all users
router.post("/getAllQuotes", (req, res) => {
  var db = getDB();
  db.all(`select * from quotes `,
    (err, row) => {
      if (err) {
        log("ERROR: " + err.message);
      }
      res.json({ quotes: row });
    });
});
//delete a quote
router.post("/deleteQuote", (req, res) => {
  var db = getDB();
  var id = req.session.userid;
  if (id === null) {
    res.redirect("/login");
  }
  var quoteId = req.body.id;
  db.run(`delete from quotes where Qid = ?`, quoteId, function (err) {
    if (err) {
      return console.error(err.message);
    }
    log(req.session.userid + " deleted quote " + quoteId);
    res.redirect("/dashboard");
  });


});
//delete user
router.get("/deleteUser", (req, res) => {
  var db = getDB();
  var id = req.session.userid;
  // NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
  // Replace the below code with two post requests to the FIDO2SERVER.
  // The first post request is to /skfs/rest/getkeysinfo which is used to
  // retrieve the user's FIDO2 Token's keyid. The second request is to
  // /skfs/rest/deregister which deletes the key.
  var username = req.session.username;
  req.session.userid = null;
  log("logout user " + id + " " + username);

  db.run(`delete from users where id = ?`, id, function (err) {
    if (err) {
      return console.error(err.message);
    }
    process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = 0;
    const data = JSON.stringify({
      svcinfo: SVCINFO,
      payload: {
        username: username
      }
    });
    const options = {
      hostname: SKFS_HOSTNAME,
      port: SKFS_PORT,
      path: SKFS_GET_KEYS_INFO_PATH,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    };
    const fido2Req = request(options, fido2Res => {
      log(`statusCode: ${fido2Res.statusCode}`);

      fido2Res.on('data', d => {
        log("keyInfo=");
        log(d);
        const dataDel = JSON.stringify({
          svcinfo: SVCINFO,
          payload: {
            "keyid": JSON.parse(d).Response.keys[0].randomid
          }
        });
        const optionsDel = {
          hostname: SKFS_HOSTNAME,
          port: SKFS_PORT,
          path: SKFS_DEREGISTER_PATH,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          }
        };
        const fido2ReqDel = request(optionsDel, fido2ResDel => {
          log(`statusCode: ${fido2ResDel.statusCode}`);

          fido2ResDel.on('data', dDel => {
            log(dDel);
            log("deleted user " + id);
            req.session.justUserDeleted = true;
            res.redirect("/login");
          })
        });
        fido2ReqDel.on('error', errorDel => {
          log(errorDel);
          res.json({ Response: "skfs-error" });
        });
        fido2ReqDel.write(dataDel);
        fido2ReqDel.end();
      })
    });
    fido2Req.on('error', error => {
      log(error);
      res.json({ Response: "skfs-error" });
    });
    fido2Req.write(data);
    fido2Req.end();
  });
  // NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN

});


//simple checks to display action response messages

//returns if the last registration was unsuccessful
router.post("/getFailedReg", (req, res) => {
  res.json({ failed: req.session.failedReg });
});
router.post("/justReg", (req, res) => {
  if (req.session.justReg) {
    req.session.justReg = false;
    res.json({ justReg: true });
  } else {
    res.json({ justReg: false });
  }
});
//returns if the user was just deleted
router.post("/justUserDeleted", (req, res) => {
  if (req.session.justUserDeleted) {
    req.session.justUserDeleted = false;
    res.json({ justUserDeleted: true });
  } else {
    res.json({ justUserDeleted: false });
  }
});


//internal src file paths

router.get("/styles/*", (req, res) => {
  _fileReader(req.url, "text/css", req, res);
});
router.get("/js/*", (req, res) => {
  _fileReader(req.url, "text/javascript", req, res);
});
router.get("/fonts/*", (req, res) => {
  _fileReader(req.url, "font/opentype", req, res);
});
router.get("/background.jpg", (req, res) => {
  _fileReader("/img/background.jpg", "image/jpeg", req, res);
});
router.get("/logo.png", (req, res) => {
  _fileReader("/img/logo.png", "image/png", req, res);
});


//catch all route
//redirects all unahandled get requests to dashboard or login depending on if
//the user is logged in
router.get('/*', (req, res) => {
  if (req.session.userid) {
    res.redirect("/dashboard");
  } else {
    res.redirect("/login");
  }
});


//database access
var getDB = function () {
  let db = new sqlite.Database('./db/aftdb.db', sqlite.OPEN_READWRITE, (err) => {
    if (err) {
      return log("getDB ERROR: " + err.message);
    }
  });
  return db;
}

//close database access
var closeDB = function (db) {
  db.close((err) => {
    if (err) {
      return log("closeDB ERROR: " + err.message);
    }
  });
}

//logging
var log = function (message) {
  appendFile('log', Date() + message + "\n", function (err) { if (err) throw err; });
}

export default router;