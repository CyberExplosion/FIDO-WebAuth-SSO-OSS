/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */

//Simple check to see if current login redirect is from a successful registration
//to display confirmation message
$.post("/justReg").done(function(data){
    justReg=data["justReg"];
    if(justReg){
      alert("Successful Registration of New User");
    }
});
//Simple check to see if current login redirect is from a successful user deletion
//to display confirmation message
$.post("/justUserDeleted").done(function(data){
    justUserDeleted=data["justUserDeleted"];
    if(justUserDeleted){
      alert("User Successfully Deleted");
    }
});
//Check if previous register submission was rejected due to username already in use
$.post("/getFailedReg").done(function(data){
    console.log(data);
    failedReg=data["failed"];
    if(failedReg == true){
      document.getElementById("failed").style.display = "inline";
      document.getElementById("failedbreak").style.display = "inline";
    }
});

//This function sets the background image settings
if(!(document.getElementById("passcontainer") === null)){
    document.body.style.backgroundImage = "linear-gradient(white,white),url(\"/background.jpg\")";
}

//This function is called when the user clicks on the password input and switches
//the input's type to password.
function makeItPassword(){
   document.getElementById("passcontainer")
      .innerHTML = "<input class=\"input-out\" id=\"password\" name=\"password\" type=\"password\"/>";
   document.getElementById("password").focus();
}


//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
// Here is where to add functions to recieve challenges and submit challenge results
// between the APPCLIENT and the APPSERVER.
// The first step in making a successful registration or authentication request is to
// get a challenge from the FIDO2SERVER. Here we send a request to the APPSERVER with
// the required data and the intent (authentication or registration). The APPSERVER 
// sends a request to the FIDO2SERVER for the appropiate challenge. Once received the
// challenge must be sent to the challengeToBuffer in the common.js file to covert the
// challenge to a format the FIDO2 authenticator can understand. After the user interacts w
// ith their authenticator of choice the authenticator will return a response. This
// response will include the signed challenge along with other information such as a
// attestation (if registration is the intent) This response is converted from a Buffer
// to Base64 (performed by the responseToBase64 function in the common.js file) so it
// is in a format the can be transferred through a post request. This converted response
// is then sent to the APPSERVER through the submitChallengeResponse post request. Upon
// receiving a successful response from the submitChallengeResponse request the user is
// redirected to the dashboard or the login page depending on the intent.



//IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
