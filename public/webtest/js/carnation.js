(function (window, $) {
  var storage = window.localStorage;

  window.carnation = window.carnation || {};
  var carnation = window.carnation;

  carnation.get_appuser_token = function (username, password, callback) {
    var access_token, valid_until, now;

    now = new Date().getTime();
    access_token = storage.getItem("carnation.appuser.token.access_token");
    valid_until = storage.getItem("carnation.appuser.token.valid_until");
    if (access_token && valid_until) {
      console.log("we have appuser access_token=" + access_token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (access_token && valid_until > now) {
      console.log("set carnation.access_token=" + access_token);
      carnation.access_token = access_token;
      callback({ 
	access_token: access_token, 
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
	data: {grant_type: "password", username: username,  password: password},
        //base64.b64encode('e3a5cde0f20a94559691364eb5fb8bff:116dd4b3a92a17453df0a5ae83e5e640')
        headers: {Authorization: "Basic ZTNhNWNkZTBmMjBhOTQ1NTk2OTEzNjRlYjVmYjhiZmY6MTE2ZGQ0YjNhOTJhMTc0NTNkZjBhNWFlODNlNWU2NDA="}
      }).done(function( token ) {
	var valid_until;
        carnation.access_token = token.access_token;
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


  carnation.get_viewer_token = function (callback) {
    var access_token, valid_until, now;
    now = new Date().getTime();
    access_token = storage.getItem("carnation.viewer.token.access_token");
    valid_until = storage.getItem("carnation.viewer.token.valid_until");
    if (access_token && valid_until) {
      console.log("we have appuser access token token=" + access_token);
      console.log("valid_until=" + valid_until);
      console.log("now=" + now);
    }
    if (access_token && valid_until > now) {
      carnation.access_token = access_token;
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
        // base64.b64encode('6052d5885f9c2a12c09ef90f815225d3:f6af879a7db8bfbe183e08c1a68e9035')
	headers: {Authorization:"Basic NjA1MmQ1ODg1ZjljMmExMmMwOWVmOTBmODE1MjI1ZDM6ZjZhZjg3OWE3ZGI4YmZiZTE4M2UwOGMxYTY4ZTkwMzU="}
      }).done(function( token ) {
	var valid_until;
        carnation.access_token = access_token;
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

  carnation.reset_appuser_token = function () {
    storage.setItem("carnation.appuser.token.valid_until", 0);
  }

  carnation.reset_viewer_token = function () {
    storage.setItem("carnation.viewer.token.valid_until", 0);
  }

  carnation.show_token = function(token) {
    $("#user_id").text(token.user_id)
    $("#viewer_id").text(token.viewer_id)
    $("#token").text(token.access_token)
    $("#token_type").text(token.token_type)
    $("#scope").text(token.scope)
    $("#valid_until").text(new Date(parseInt(token.valid_until)))
  }

  carnation.callapi = function(form) {
    var result_window = window.open("", "result");
    var serialized_form = form.serialize();
    $(form).find('#description').html('');
    $(form).find('#description').append(form.attr('method') + '<br/>');
    $(form).find('#description').append(form.attr('action') + '<br/>');
    $(form).find('#description').append(serialized_form);

    $.ajax({
      url: form.attr('action'),
      type: form.attr('method'),
      data: form.serialize(),
      headers: {Authorization:"Bearer " + carnation.access_token}
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

  $(".carnation_api").submit( function (event) {
    console.log( "carnation_api" );
    event.preventDefault();
    console.log( "token=" + carnation.access_token );
    var form = $(this);
    carnation.callapi(form);
  });
}(window, jQuery));

