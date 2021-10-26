// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require_tree .

(function($) {

    window.progress = {

        compareLoading: function() {
            $('#compare-url').click(function() {
                if (!$('#compare-progress-bar-container').hasClass('show')) {
                    $('#compare-progress-bar-container').addClass('show');
                    var fds = parseFloat($('.client-connected').text().match(/(\d+)(?!.*\d)/)[0]);
                    var percent = 0.0;
                    var update = setInterval(function() {
                        if (percent > 99.5) {
                            clearInterval(update);
                        } else {
                            try {
                                percent += (400.0 / fds);
                                $('.compare-progress-bar')
                                    .attr('aria-valuenow', percent.toFixed(2))
                                    .css('width', percent.toFixed(2) + '%')
                                    .text(percent.toFixed(2) + '%');
                            } catch (e) {
                                clearInterval(update);
                            }
                        }
                    }, 25);
                }
            })
        },
        initializeTooltips: function() {
            $('[data-toggle="tooltip"]').tooltip();
        }

    }

    $(document).on('turbolinks:load', function() {
        window.progress.compareLoading();
        window.progress.initializeTooltips();
    });

})(jQuery)