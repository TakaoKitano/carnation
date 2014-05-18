(function (exports, $) {
  var carnation = exports.carnation;

  carnation.get_appuser_token(
    function(token) {
      //console.log("carnation token.access_token=" + token.access_token);
      //console.log("carnation token.valid_until=" + token.valid_until);
      //console.log("carnation token.user_id=" + token.user_id);
      $("#user_id").text(token.user_id)
      $("#token").text(token.access_token)
      $("#token_type").text(token.token_type)
      $("#scope").text(token.scope)
      $("#valid_until").text(new Date(parseInt(token.valid_until)))
    }
  );

}(window, jQuery));
