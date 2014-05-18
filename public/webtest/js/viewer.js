(function (exports, $) {
  var carnation = exports.carnation;

  carnation.get_viewer_token(
    function(token) {
      console.log("carnation token.access_token=" + token.access_token);
    }
  );

}(window, jQuery));
