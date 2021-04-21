/*
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Close login page opened as child window. */
$(function() {
    $('body.backToMom').each(function(){
        setTimeout(function(){
            if (window.opener) {
                var url = window.opener.location.href;
                if (url.indexOf('logout') > -1 )
                    url = sympa.home_url;
                window.opener.location = url;
            }
            window.close();
        }, 1000);
    });
});

/* Open in a new window. */
$(function() {
    $('.openInNewWindow').on('click', function(){
        window.open($(this).attr('href'), $(this).attr('target'),
            'toolbar=no,location=no,directories=no,status=no,menubar=no,' +
            'scrollbars=yes,resizable=yes,copyhistory=no,' +
            'width=400,height=200');
        return false;
    }).each(function(){
        $(this).attr('title', sympa.openInNewWinText);
    });
});

/* Loading foundation. */
$(function() {
    Foundation.Drilldown.defaults.backButton =
        '<li class="js-drilldown-back"><a tabindex="0">' + sympa.backText
            + '</a></li>';
    $(document).foundation();
});

/* Show error dialog.  It may be closed only when javascript is enabled. */
$(function() {
    var closeButton =
        $('<a class="close-button" data-close aria-label="' + sympa.closeText
            + '" aria-hidden="true">&times;</a>');
    $('#ErrorMsg').append(closeButton);
    $('#ErrorMsg').each(function(){
        var revealModal = new Foundation.Reveal($(this));
        revealModal.open();
    });
});

/*
 * No longer used as of 6.2.17, however, can be included in older archives.
 */
function isNotEmpty(i) { return true; }
function request_confirm(m) { return true; }
function toggle_selection(myfield) { return false; }

/* Toggle selection. */
/* Fields included in .toggleContainer and specified by data-selector
 * will be toggled by clicking .toggleButton. */
$(function() {
    /* Compatibility for older archives created by Sympa prior to 6.2.17. */
    $('form#msglist').each(function(){
        $(this).addClass('toggleContainer')
            .data('toggle-selector', 'input[name="msgid"]');
        $(this).find('input[type="button"]').addClass('toggleButton');
    });

    $('.toggleContainer').each(function(){
        var container = this;
        var selector = $(this).data('toggle-selector');
        $(this).find('.toggleButton').on('click', function(){
            $(container).find(selector).each(function(){
                $(this).prop('checked', !$(this).is(':checked'));
                $(this).trigger('change');
            });
            return false;
        });
    });
});

// check if rejecting quietly spams TODO
function check_reject_spam(form,warningId) {
	if(form.elements['iConfirm'].checked) return true;
	
	if(form.elements['message_template'].options[form.elements['message_template'].selectedIndex].value ==  'reject_quiet') return true;
	
	$('#' + warningId).show();
	return false;
}

// To check at least one checkbox checked
function checkbox_check_topic(form, warningId) {
	if($(form).find('input[name^="topic_"]:checked').length) return true;
	
	$('#' + warningId).show();
	return false;
}

/* Add a button to reset all fields in log form. */
$(function() {
    var logsForm = $('#logs_form');
    var resetButton = 
        $('<input class="MainMenuLinks" id="btnreset" type="button" value="'
            + sympa.resetText + '" />');
    logsForm.append(resetButton);

    $('#btnreset').on('click', function(){
        logsForm.find('[name="type"]').val('all_actions');
        logsForm.find('[name="target_type"]').val('msg_id');
        logsForm.find('input[type="text"]').val('');
    });
});

/* Submit immediately if the widget with class 'submitOnChange' is changed. */
$(function() {
    $('.submitOnChange').on('change', function(){
        $(this).closest('form').submit();
    });
});

/* Loading color picker widget. */
$(function() {
    if ($.minicolors) {
        // jQuery MiniColors
        // https://labs.abeautifulsite.net/jquery-minicolors/
        $('input.colorPicker').each(function(){
            $(this).minicolors({
                defaultValue: $(this).data('color')
            });
            $(this).closest('.columns').css('overflow', 'visible');
        });
    }
});

/* Loading jQuery-UI Datepicker Widget. */
$(function() {
    var options = {
        buttonText:      sympa.calendarButtonText,
        changeMonth:     true,
        changeYear:      true,
        dateFormat:      'dd-mm-yy',
        dayNames:        sympa.dayNames,
        dayNamesMin:     sympa.dayNamesMin,
        firstDay:        sympa.calendarFirstDay,
        monthNamesShort: sympa.monthNamesShort,
        shortYearCutoff: 50,
        showOn:          "button"
    };
    $('#date_deb').datepicker(options);
    $('#date_from').datepicker(options);
    $('#date_fin').datepicker(options);
    $('#date_to').datepicker(options);
});

/* Emulates AJAX reveal modal button of Foundation 5. */
/* The element specified by data-reveal-id is the container of content
 * specified by href attribute of the item which have data-reveal-ajax="true".
 */
$(function() {
    $('a[data-reveal-ajax="true"]').on('click', function(){
        var revealId = '#' + $(this).data('reveal-id');
        $.ajax($(this).attr('href')).done(function(content){
            $(revealId).html(content);
            var revealModal = new Foundation.Reveal($(revealId));
            revealModal.open();
            /* Add "Close" button to popup. */
            var closeButton =
                $('<a class="close-button" data-close aria-label="'
                    + sympa.closeText + '" aria-hidden="true">&times;</a>');
            $(revealId).append(closeButton);
        });

        return false;
    });
});

// Show "Please wait..." spinner icon.
$(function() {
	var loadingText =
	$('<h1 id="loadingText"><i class="fa fa-spinner fa-pulse"></i> ' +
		sympa.loadingText + '</h1>');
	$('#loading').append(loadingText);

	$('.heavyWork').on('click', function(){
		$('#loading').show();
	});
});

// fade effect for notification boxes
$(function() {
	$('#ephemeralMsg').delay(500).fadeOut(4000);
});

/* Check if the value of field(s) specified by data-selector is empty. */
$(function() {
    $('.disableIfEmpty').each(function(){
        var target = this;
        var selector = $(this).data('selector');
        $(selector).on('keyup change', function(){
            var isEmpty = false;
            $(selector).each(function(){
                var val = $(this).val();
                if (val && val.replace(/\s+/g, '').length)
                    return true;
                isEmpty = true;
                return false;
            });
            $(target).prop('disabled', isEmpty);
        });
        $(selector).trigger('change');
    });
});

/* Check if any of fields specified by data-selector are checked. */
$(function () {
    $('.disableUnlessChecked').each(function(){
        var target = this;
        var selector = $(this).data('selector');
        $(selector).on('change', function(){
            var isChecked = false;
            $(selector).each(function(){
                if ($(this).prop('checked')) {
                    isChecked = true;
                    return false;
                }
                return true;
            });
            $(target).prop('disabled', !isChecked);
        });
        $(selector).trigger('change');
    });
});

/* If checked, fade off item specified by data-selector. */
$(function() {
    $('.fadeIfChecked').each(function(){
        var selector = $(this).data('selector');
        $(this).on('change', function(){
            if ($(this).prop('checked'))
                $(selector).fadeTo('normal', 0.3);
            else
                $(selector).fadeTo('normal', 1);
        });
    });
});

/* Help button to hide/show online help.
   It may be closed only when javascript is enabled. */
$(function() {
    $('.accordionButton').each(function(){
        var selector = $(this).data('selector');
        $(this).on('click', function(){
            $(selector).slideToggle('normal');
            return false;
        });

        var closeButton =
            $('<a class="close-button" data-close aria-label="'
                + sympa.closeText + '" aria-hidden="true">&times;</a>');
        $(selector).append(closeButton);
        $(selector).hide();
    });
});

/* Top button. */
$(function() {
    var scrollTopInner = $('<span class="scroll-top-inner">' +
        '<i class="fa fa-2x fa-arrow-circle-up"></i></span>');
    $('.scroll-top-wrapper').append(scrollTopInner);

    $(document).on('scroll', function(){
        if ($(window).scrollTop() > 100) {
            $('.scroll-top-wrapper').addClass('show');
        } else {
            $('.scroll-top-wrapper').removeClass('show');
        }
    });

    $('.scroll-top-wrapper').on('click', function(){
        $('html, body')
            .animate({scrollTop: $('body').offset().top}, 500, 'linear');
    });
});

/* Replace line breaks in tooltip by Foundation (See GH issue #562). */
$(function() {
    $('div.tooltip').each(function(){
        var tooltip = $(this);
        tooltip.html(tooltip.html().replace(/\r\n|\r|\n/g, '<br />'));
        return true;
    });
});

