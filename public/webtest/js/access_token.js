(function (exports, $) {
  var storage = exports.localStorage;

  exports.carnation = exports.carnation || {};
  exports.carnation.get_appuser_token = function (callback) {
    var token, valid_until, now;
    now = new Date().getTime();
    token = storage.getItem("carnation.appuser.token.access_token");
    valid_until = storage.getItem("carnation.appuser.token.valid_until");
    if (token && valid_until) {
      console.log("we have appuser access token token=" + token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (token && valid_until > now) {
      callback({ 
	access_token: token, 
	user_id: storage.getItem("carnation.appuser.token.user_id"),
	scope: storage.getItem("carnation.appuser.token.scope"),
	token_type: storage.getItem("carnation.appuser.token.token_type"),
	valid_until: valid_until
       });
    } else {
      console.log("retrieving appuser access token");
      $.ajax({
	type: "POST",
	url: "/token",
	dataType: "json",
	data: {grant_type: "password", username: "user1@chikaku.com",  password:"mago"},
        headers: {Authorization: "Basic MGEwYzliODc2MjJkZWY0ZGE1ODAxZWRkN2UwMTNiNGQ6ZDE1NzJkOGNkNDY5MTM2MzBkZmM1NmY0ODFkYjgxOGI="}
      }).done(function( token ) {
	var valid_until;
	storage.setItem("carnation.appuser.token.access_token", token.access_token);
	storage.setItem("carnation.appuser.token.expires_in", token.expires_in);
	storage.setItem("carnation.appuser.token.token_type", token.token_type);
	storage.setItem("carnation.appuser.token.scope", token.scope);
	storage.setItem("carnation.appuser.token.user_id", token.user_id);
	valid_until = new Date((new Date()).getTime() + token.expires_in * 1000).getTime()
	storage.setItem("carnation.appuser.token.valid_until", valid_until);
	console.log("access_token=" + token.access_token); 
	console.log("expires_in=" + token.expires_in); 
	console.log("token_type=" + token.token_type); 
	console.log("scope=" + token.scope); 
	console.log("valid_until=" + valid_until);
	console.log("user_id=" + token.user_id);
        callback({ 
	  access_token: token.access_token, 
	  user_id: token.user_id,
	  scope: token.scope,
	  token_type: token.token_type,
	  valid_until: valid_until
	 });
      });
    }
  };

  exports.carnation.get_viewer_token = function (callback) {
    var token, valid_until, now;
    now = new Date().getTime();
    token = storage.getItem("carnation.viewer.token.access_token");
    valid_until = storage.getItem("carnation.viewer.token.valid_until");
    if (token && valid_until) {
      console.log("we have appuser access token token=" + token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (token && valid_until > now) {
      callback({ 
	access_token: token, 
	viewer_id: storage.getItem("carnation.viewer.token.viewer_id"),
	scope: storage.getItem("carnation.viewer.token.scope"),
	token_type: storage.getItem("carnation.viewer.token.token_type"),
	valid_until: valid_until
       });
    } else {
      console.log("retrieving viewer access token");
      $.ajax({
	type: "POST",
	url: "/token",
	dataType: "json",
	data: {locale:"en", grant_type:"client_credentials"},
	headers: {Authorization:"Basic NjA1MmQ1ODg1ZjljMmExMmMwOWVmOTBmODE1MjI1ZDM6ZjZhZjg3OWE3ZGI4YmZiZTE4M2UwOGMxYTY4ZTkwMzU="}
      }).done(function( token ) {
	var valid_until;
	storage.setItem("carnation.viewer.token.access_token", token.access_token);
	storage.setItem("carnation.viewer.token.expires_in", token.expires_in);
	storage.setItem("carnation.viewer.token.token_type", token.token_type);
	storage.setItem("carnation.viewer.token.scope", token.scope);
	storage.setItem("carnation.viewer.token.viewer_id", token.viewer_id);
	valid_until = new Date((new Date()).getTime() + token.expires_in * 1000).getTime()
	storage.setItem("carnation.viewer.token.valid_until", valid_until);
	console.log("access_token=" + token.access_token); 
	console.log("expires_in=" + token.expires_in); 
	console.log("token_type=" + token.token_type); 
	console.log("scope=" + token.scope); 
	console.log("valid_until=" + valid_until);
	console.log("viewer_id=" + token.viewer_id);
	callback({ 
	  access_token: token.access_token, 
	  viewer_id: token.viewer_id,
	  scope: token.scope,
	  token_type: token.token_type,
	  valid_until: valid_until
        });
      });
    }
  };
}(window, jQuery));

