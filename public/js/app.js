(function() {
  var App = {

    init: function() {
      if ($('#search-form').length > 0)
        Form.init();
    }

  },

  Form = {

    autocompleteSource: function(request, response) {
      var countryCode = $(this.element[0]).data('countrycode');
      $.ajax({
        url: "http://ws.geonames.org/searchJSON",
        dataType: "jsonp",
        data: {
          featureClass: "P",
          style: "full",
          country: countryCode,
          lang: $('html').attr('lang'),
          maxRows: 12,
          name_startsWith: request.term
        },
        success: function( data ) {
          response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name
            }
          }));
        }
      });
    },

    autocompleteOpen: function() {
      $( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
    },

    autocompleteClose: function() {
      $( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
    },

    countryChange: function(e) {
      var textInput = $(this).parent().children("input[type=\"text\"]");
      var optionValue = $(this).find("option:selected").val();
      var countryCode = $(this).find("option:selected").data('countrycode');

      if (optionValue != '' && textInput.attr('disabled')){
        textInput.removeAttr('disabled');
      } else if (optionValue == '' && !textInput.attr('disabled')){
        textInput.attr('disabled', true);
      }

      textInput.data('countrycode', countryCode);
    },

    events: function() {
      $('#from-city, #to-city').autocomplete({
        source: Form.autocompleteSource,
        minLength: 2,
        open: Form.autocompleteOpen,
        close: Form.autocompleteClose
      });

      $('#from-country, #to-country').change(Form.countryChange);

    },

    disableCityInputs: function() {
      if ($("#from-city").val().length == 0 || $("#to-city").val().length == 0)
        $('#from-city, #to-city').attr('disabled', true);
    },

    init: function() {
      this.events();
      this.disableCityInputs();
      $("#when-date").datepicker({ dateFormat: "dd-mm-yy" });
    }

  }

  $(document).ready(App.init);
})();
