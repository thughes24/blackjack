$(document).ready(function() {

  $(document).on('click', '#playershit', function() {
    $.ajax({
      type: "POST",
      url: "/player/hit"
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#playersstay input', function() {
    $.ajax({
      type: "POST",
      url: "/player/stay"
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#dealershit', function() {
    $.ajax({
      type: "POST",
      url: "/dealer/hit"
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
    return false;
  });
});
