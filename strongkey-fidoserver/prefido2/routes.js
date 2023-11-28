/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */
var dateFormat = require('dateformat');
var fs = require('fs');
var crypto = require('crypto');
var fileReader = require('./fileReader');
var url = require('url');
var express = require('express');
var session = require('express-session')
var router = express.Router();
const sqlite3 = require("sqlite3").verbose();
router.use(express.static('public'));

// LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
// Add a 'const https = require('https');' This is what is used to make http requests
// to the FIDO2 server.
// Add 'const CONSTANTS = require('./constants');'
// LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL



failedRegistration=null;


//Template routes

//route for dashboard.html
router.get('/dashboard', (req, res) => {
    log(req.session.userid);
    //Checking if user is logged in
    if(req.session.userid){
      fileReader.fileReader("/dashboard.html","text/html",req,res);
    } else {
      res.redirect("/login");
    }

});
//route for login.html
router.get('/login', (req, res) => {
    fileReader.fileReader("/login.html","text/html",req,res);
});
//route for register.html
router.get('/register', (req, res) => {
    req.session.failedReg=false;
    //checks if registration failed on last request to show failed to register
    //message
    if(failedRegistration){
      req.session.failedReg=true;
    }
    fileReader.fileReader("/register.html","text/html",req,res);
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
router.post("/loginSubmit", (req,res) =>{
  var username = req.body.username;
  var password = req.body.password;
  //if username or password fields are empty then login fail
  if(username == "" | password==""){
    res.redirect("/login");
    return;
  }
  //convert password into hmac to compare with database entry
  const passwordHash = crypto.createHmac('sha256', password).digest('hex');
  var db = getDB();
  //verify credentials with database
  db.get(`select * from users where username = ? and password = ? `,[username,passwordHash],
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     if (row) {
       //addes userid to session to signify user logged in
       req.session.userid = row.id;
       log(row["username"]+" signed in");
       //redirect to dashboard.html
       req.session.save(function(err) {
         res.redirect("/dashboard");
        })
      } else {
        //if credentials are not found in the database then redirect to login.html
        res.redirect("/login");
        return;
      }
    });
  });
//creates new user upon register submit
router.post("/registerSubmit", (req,res) =>{
  var firstname = req.body.firstname;
  var lastname = req.body.lastname;
  var username = req.body.username;
  var password= req.body.password;
  //if any inputs are empty then don't register
  if(username == "" | password=="" | firstname == "" | lastname == ""){
    res.redirect("/register");
    return;
  }
  //convert password into hmac for database storage
  const passwordHash = crypto.createHmac('sha256', password).digest('hex');
  var db = getDB();
  //check if username already exists in database
  db.get(`select * from users where username = ? `,[username],
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     if (!row) {
       //insert new user to database if user does not already exist
      db.run('insert into users(username,password,first_name,last_name) values(?,?,?,?)',[username,passwordHash,firstname,lastname], function(err) {
      if (err) {log("ERROR: "+ err.message);}
          log("user added: \nfirst name: "+firstname+"\nlast name: "+lastname+"\nusername: "+username);
          req.session.justReg=true;
          res.redirect("/login");
        });
      } else {
        failedRegistration=true;
        res.redirect("/register");
      }
    });
});

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

//add a quote
router.post("/addQuote", (req,res) =>{
  var id = req.session.userid;
  var name = req.body.name;
  var now = new Date();
  var date = dateFormat(now, "ddd mmm dd yyyy HH:MM:ss Z");
  var filepath = req.body.filepath;
  var db = getDB();
  //checking if quote is already in database
  db.get(`select * from quotes where name = ? or filepath = ? `,[name,filepath],
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     if(!row){
       //adding quote to database
       db.run('insert into quotes(uploader,name,date,filepath) values(?,?,?,?)',[id, name, date, filepath], function(err) {
           if (err) {log("ERROR: "+ err.message);}
           log("quote added: name: "+name+"\nuploader: "+id+"\nfilepath: "+filepath);
           res.redirect("/dashboard");
       });
     } else {
       res.redirect("/dashboard");
     }
    });
  });

//logging out current user
router.get("/logout", (req,res)=>{
  log(req.session.userid+" signed out");
  req.session.userid=null;
  res.redirect("/login");
});
//getting username from database
router.post("/getUsername", (req,res) =>{
  var db = getDB();
  var id = req.session.userid;

  db.get(`select username from users where id = ? `,[id],
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     res.json({userData:row});
  });
});
//get quotes based on currently signed in uploader
router.post("/getQuotes", (req,res) =>{
  var db = getDB();
  var id = req.session.userid;

  db.all(`select * from quotes where uploader = ? `,[id],
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     res.json({quotes:row});
  });
});
//get all quotes from all users
router.post("/getAllQuotes", (req,res) =>{
  var db = getDB();
  db.all(`select * from quotes `,
     (err, row) => {
     if (err) {
       log("ERROR: "+ err.message);
     }
     res.json({quotes:row});
  });
});
//delete a quote
router.post("/deleteQuote", (req,res) =>{
  var db = getDB();
  var id = req.session.userid;
  if(id === null){
    res.redirect("/login");
  }
  var quoteId = req.body.id;
  db.run(`delete from quotes where Qid = ?`, quoteId, function(err) {
      if (err) {
        return console.error(err.message);
      }
    log(req.session.userid+" deleted quote " +quoteId);
    res.redirect("/dashboard");
  });


});
//delete user
router.get("/deleteUser", (req,res) =>{
  var db = getDB();
  var id = req.session.userid;
  // NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
  // Replace the below code with two post requests to the FIDO2SERVER.
    // The first post request is to /skfs/rest/getkeysinfo which is used to
  // retrieve the user's FIDO2 Token's keyid. The second request is to
  // /skfs/rest/deregister which deletes the key.
  req.session.userid=null;
  log("logout user " +id);

   db.run(`delete from users where id = ?`, id, function(err) {
       if (err) {
         return console.error(err.message);
       }

     log("deleted user " +id);
     req.session.justUserDeleted = true;
     res.redirect("/login");

   });
   // NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN

});


//simple checks to display action response messages

//returns if the last registration was unsuccessful
router.post("/getFailedReg", (req,res) =>{
  res.json({failed:req.session.failedReg});
});
router.post("/justReg", (req,res) =>{
  if (req.session.justReg){
    req.session.justReg = false;
    res.json({justReg:true});
  } else {
    res.json({justReg:false});
  }
});
//returns if the user was just deleted
router.post("/justUserDeleted", (req,res) =>{
  if (req.session.justUserDeleted){
    req.session.justUserDeleted = false;
    res.json({justUserDeleted:true});
  } else {
    res.json({justUserDeleted:false});
  }
});


//internal src file paths

router.get("/styles/*", (req,res) =>{
  fileReader.fileReader(req.url,"text/css",req,res);
});
router.get("/js/*", (req,res) =>{
  fileReader.fileReader(req.url,"text/javascript",req,res);
});
router.get("/fonts/*", (req,res) =>{
  fileReader.fileReader(req.url,"font/opentype",req,res);
});
router.get("/background.jpg", (req,res) =>{
  fileReader.fileReader("/img/background.jpg","image/jpeg",req,res);
});
router.get("/logo.png", (req,res) =>{
  fileReader.fileReader("/img/logo.png","image/png",req,res);
});


//catch all route
//redirects all unahandled get requests to dashboard or login depending on if
//the user is logged in
router.get('/*', (req, res) => {
  if(req.session.userid){
    res.redirect("/dashboard");
  } else {
    res.redirect("/login");
  }
});


//database access
var getDB = function(){
  let db = new sqlite3.Database('./db/aftdb.db',sqlite3.OPEN_READWRITE, (err) => {
    if (err) {
      return log("getDB ERROR: "+ err.message);
    }
  });
  return db;
}

//close database access
var closeDB = function(db){
  db.close((err) => {
    if (err) {
      return log("closeDB ERROR: "+ err.message);
    }
  });
}

//logging
var log = function(message){
  fs.appendFile('log', Date()+message+"\n", function (err) {if (err) throw err;});
}

module.exports = router;
