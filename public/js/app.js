(function() {
  var App = {

    init: function() {
      if ($('#search-form').length > 0)
        Form.init();
    }

  },

  Form = {

    events: function() {
    },

    init: function() {
      this.events();
      $("#when-date").datepicker({
        dateFormat: "dd-mm-yy"
      });
    }

  }

  $(document).ready(App.init);
})();
