(function() {
  var App = {

    init: function() {
      if ($('#search-form').length > 0)
        Form.init();
      else if ($('#feedback-form').length > 0)
        Feedback.init();
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

  },

  Feedback = {

    displayCaptcha: function() {
      Recaptcha.create($('#recaptcha').data('pubkey'),
        "recaptcha",
        {
          theme: $('#recaptcha').data('theme'),
          lang: $('#recaptcha').data('lang'),
          callback: Recaptcha.focus_response_field
        }
      );
    },

    resetErrors: function() {
      $('div.control-group').removeClass('error');
      $('span.help-inline').remove()
    },

    getResults: function(data) {
      Feedback.resetErrors();

      if (!data.success) {
        Feedback.displayCaptcha();
        var errors = JSON.parse(data.errors);

        console.log(data.recaptcha_error);

        if (data.recaptcha_error){
          $('#recaptcha').parent('.control-group').addClass('error');
          $('#recaptcha').parent('.control-group')
                         .append('<span class="help-inline">Captcha</span>');
        }

        for (el in errors){
          var controlGroup = $('#'+el).parent('.control-group');
          controlGroup.addClass('error');
          controlGroup.append('<span class="help-inline">'+errors[el]+'</span>');
        }
      } else {
        $('#feedback-alert').parent().removeClass('hide');
        $('#feedback-alert').removeClass('out').addClass('in');
      }
    },

    submitForm: function(e) {
      e.preventDefault();
      var serializedData = $(this).serialize();
      var actionUrl = $(this).attr('action');

      $.ajax({
        url: actionUrl,
        data: serializedData,
        type: 'POST'
      }).done(Feedback.getResults);
    },

    events: function() {
      $('#feedback-form').submit(this.submitForm);
    },

    init: function() {
      this.events();
      this.displayCaptcha();
    }

  }

  $(document).ready(App.init);
})();
