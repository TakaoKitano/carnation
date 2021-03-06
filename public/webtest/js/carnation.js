(function (window, $) {
  var storage = window.localStorage;

  window.carnation = window.carnation || {};
  var carnation = window.carnation;

  carnation.get_user_token = function (auth_basic, username, password, callback) {
    var access_token, valid_until, now;

    now = new Date().getTime();
    access_token = storage.getItem("carnation.user.token.access_token");
    refresh_token = storage.getItem("carnation.user.token.refresh_token");
    valid_until = storage.getItem("carnation.user.token.valid_until");
    if (access_token && valid_until) {
      console.log("we have user access_token=" + access_token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (access_token && valid_until > now) {
      callback({ 
	access_token: access_token, 
	refresh_token: refresh_token, 
	user_id: storage.getItem("carnation.user.token.user_id"),
	scope: storage.getItem("carnation.user.token.scope"),
	token_type: storage.getItem("carnation.user.token.token_type"),
	valid_until: valid_until
       });
    } else {
      console.log("retrieving user access token");
      $.ajax({
	type: "POST",
	url: "/token",
	dataType: "json",
	data: {grant_type: "password", username: username,  password: password},
	headers: {Authorization:auth_basic}
      }).done(function( token ) {
	var valid_until;
	storage.setItem("carnation.user.token.access_token", token.access_token);
	storage.setItem("carnation.user.token.refresh_token", token.refresh_token);
	storage.setItem("carnation.user.token.expires_in", token.expires_in);
	storage.setItem("carnation.user.token.token_type", token.token_type);
	storage.setItem("carnation.user.token.scope", token.scope);
	storage.setItem("carnation.user.token.user_id", token.user_id);
	valid_until = new Date((new Date()).getTime() + token.expires_in * 1000).getTime()
	storage.setItem("carnation.user.token.valid_until", valid_until);
	console.log("access_token=" + token.access_token); 
	console.log("refresh_token=" + token.refresh_token); 
	console.log("expires_in=" + token.expires_in); 
	console.log("token_type=" + token.token_type); 
	console.log("scope=" + token.scope); 
	console.log("valid_until=" + valid_until);
	console.log("user_id=" + token.user_id);
        callback({ 
	  access_token: token.access_token, 
	  refresh_token: token.refresh_token, 
	  user_id: token.user_id,
	  scope: token.scope,
	  token_type: token.token_type,
	  valid_until: valid_until
	 });
      });
    }
  };

  carnation.refresh_user_token = function (auth_basic, refresh_token, callback) {
      console.log("refresh user access token");
      $.ajax({
	type: "POST",
	url: "/token",
	dataType: "json",
	data: {grant_type: "refresh_token", refresh_token: refresh_token},
	headers: {Authorization:auth_basic}
      }).done(function( token ) {
	var valid_until;
	storage.setItem("carnation.user.token.access_token", token.access_token);
	storage.setItem("carnation.user.token.refresh_token", token.refresh_token);
	storage.setItem("carnation.user.token.expires_in", token.expires_in);
	storage.setItem("carnation.user.token.token_type", token.token_type);
	storage.setItem("carnation.user.token.scope", token.scope);
	storage.setItem("carnation.user.token.user_id", token.user_id);
	valid_until = new Date((new Date()).getTime() + token.expires_in * 1000).getTime()
	storage.setItem("carnation.user.token.valid_until", valid_until);
	console.log("access_token=" + token.access_token); 
	console.log("refresh_token=" + token.refresh_token); 
	console.log("expires_in=" + token.expires_in); 
	console.log("token_type=" + token.token_type); 
	console.log("scope=" + token.scope); 
	console.log("valid_until=" + valid_until);
	console.log("user_id=" + token.user_id);
        callback({ 
	  access_token: token.access_token, 
	  refresh_token: token.refresh_token, 
	  user_id: token.user_id,
	  scope: token.scope,
	  token_type: token.token_type,
	  valid_until: valid_until
	 });
      });
  }

  carnation.get_viewer_token = function (auth_basic, callback) {
    var access_token, valid_until, now;
    now = new Date().getTime();
    access_token = storage.getItem("carnation.viewer.token.access_token");
    valid_until = storage.getItem("carnation.viewer.token.valid_until");
    if (access_token && valid_until) {
      console.log("we have viewer access token token=" + access_token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (access_token && valid_until > now) {
      callback({ 
	access_token: access_token, 
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
	headers: {Authorization:auth_basic}
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
  }

  carnation.reset_user_token = function () {
    storage.setItem("carnation.user.token.valid_until", 0);
  }

  carnation.reset_viewer_token = function () {
    storage.setItem("carnation.viewer.token.valid_until", 0);
  }

  carnation.callapi = function(form, token) {
    var result_window = window.open("", "result");
    var serialized_form = form.serialize().replace('&tokentype=user', '').replace('&tokentype=viewer', '');
    var parameters = form.attr('method') + ' ' + form.attr('action') + '\n' + serialized_form;
    
    $(form).find('#parameters').text(parameters)

    $.ajax({
      url: form.attr('action'),
      type: form.attr('method'),
      data: form.serialize(),
      headers: {Authorization:"Bearer " + token}
    }).done(function( data ) {
      with(result_window.document)
      {
        open();
        write("<html><body><pre>");
        write(JSON.stringify(data, null, "  "));
        write("</pre></body><html>");
        close();
      }
    }).error(function( data ) {
      console.log("server returns error");
      with(result_window.document)
      {
        open();
        write(data.responseText);
        close();
      }
    });
  }

}(window, jQuery));

