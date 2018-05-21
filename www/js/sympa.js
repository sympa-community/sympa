/*
 * Copyright 2010-2018 The Sympa Community. Licensed under GNU GPL v2
 * See license text at https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
 */

// To confirm on a link (A HREF)
function refresh_mom_and_die() {
  url = window.opener.location.href;
  if (url.indexOf('logout') > -1 ) {
    url = sympa.home_url;
  }
  window.opener.location = url;
  self.close();
}

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
            });
            return false;
        });
    });
});

function chooseColorNumber(cn, cv) {
    $('#custom_color_number').val(cn);
    if (cv) {
      $('#custom_color_value').val(cv);
      $('#custom_color_value').trigger('change');
    }
}

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

// Here are some boring utility functions. The real code comes later.

function hexToRgb(hex_string, default_)
{
    if (default_ == undefined)
    {
        default_ = null;
    }

    if (hex_string.substr(0, 1) == '#')
    {
        hex_string = hex_string.substr(1);
    }
    
    var r;
    var g;
    var b;
    if (hex_string.length == 3)
    {
        r = hex_string.substr(0, 1);
        r += r;
        g = hex_string.substr(1, 1);
        g += g;
        b = hex_string.substr(2, 1);
        b += b;
    }
    else if (hex_string.length == 6)
    {
        r = hex_string.substr(0, 2);
        g = hex_string.substr(2, 2);
        b = hex_string.substr(4, 2);
    }
    else
    {
        return default_;
    }
    
    r = parseInt(r, 16);
    g = parseInt(g, 16);
    b = parseInt(b, 16);
    if (isNaN(r) || isNaN(g) || isNaN(b))
    {
        return default_;
    }
    else
    {
        return {r: r / 255, g: g / 255, b: b / 255};
    }
}

function rgbToHex(r, g, b, includeHash)
{
    r = Math.round(r * 255);
    g = Math.round(g * 255);
    b = Math.round(b * 255);
    if (includeHash == undefined)
    {
        includeHash = true;
    }
    
    r = r.toString(16);
    if (r.length == 1)
    {
        r = '0' + r;
    }
    g = g.toString(16);
    if (g.length == 1)
    {
        g = '0' + g;
    }
    b = b.toString(16);
    if (b.length == 1)
    {
        b = '0' + b;
    }
    return ((includeHash ? '#' : '') + r + g + b).toUpperCase();
}

var arVersion = navigator.appVersion.split("MSIE");
var version = parseFloat(arVersion[1]);

function fixPNG(myImage)
{
    if ((version >= 5.5) && (version < 7) && (document.body.filters)) 
    {
        var node = document.createElement('span');
        node.id = myImage.id;
        node.className = myImage.className;
        node.title = myImage.title;
        node.style.cssText = myImage.style.cssText;
        node.style.setAttribute('filter', "progid:DXImageTransform.Microsoft.AlphaImageLoader"
                                        + "(src=\'" + myImage.src + "\', sizingMethod='scale')");
        node.style.fontSize = '0';
        node.style.width = myImage.width.toString() + 'px';
        node.style.height = myImage.height.toString() + 'px';
        node.style.display = 'inline-block';
        return node;
    }
    else
    {
        return myImage.cloneNode(false);
    }
}

function trackDrag(node, handler)
{
    function fixCoords(ev)
    {
        var e = ev.originalEvent.changedTouches
            ? ev.originalEvent.changedTouches[0] : ev;
        x = e.pageX - $(node).offset().left;
        y = e.pageY - $(node).offset().top;
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x > node.offsetWidth - 1) x = node.offsetWidth - 1;
        if (y > node.offsetHeight - 1) y = node.offsetHeight - 1;
        return {x: x, y: y};
    }
    var _pointer = (function()
    {
        if (window.navigator.pointerEnabled) // Pointer events (IE11+)
        {
            return {down: 'pointerdown', move: 'pointermove', up: 'pointerup'};
        }
        else if ('ontouchstart' in window)   // Touch events
        {
            return {down: 'touchstart', move: 'touchmove', up: 'touchend'};
        }
        else
        {
            return {down: 'mousedown', move: 'mousemove', up: 'mouseup'};
        }
    })();
    function mouseDown(ev)
    {
        var coords = fixCoords(ev);
        var lastX = coords.x;
        var lastY = coords.y;
        handler(coords.x, coords.y);

        function moveHandler(ev)
        {
            var coords = fixCoords(ev);
            if (coords.x != lastX || coords.y != lastY)
            {
                lastX = coords.x;
                lastY = coords.y;
                handler(coords.x, coords.y);
            }
        }
        function upHandler(ev)
        {
            $(document).off(_pointer.up, upHandler);
            $(document).off(_pointer.move, moveHandler);
            $(node).on(_pointer.down, mouseDown);
        }
        $(document).on(_pointer.up, upHandler);
        $(document).on(_pointer.move, moveHandler);
        $(node).off(_pointer.down, mouseDown);
        if (ev.preventDefault) ev.preventDefault();
    }
    $(node).on(_pointer.down, mouseDown);
}

// This copyright statement applies to the following two functions,
// which are taken from MochiKit.
//
// Copyright 2005 Bob Ippolito <bob@redivi.com>
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject
// to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

function hsvToRgb(hue, saturation, value)
{
    var red;
    var green;
    var blue;
    if (value == 0.0)
    {
        red = 0;
        green = 0;
        blue = 0;
    }
    else
    {
        var i = Math.floor(hue * 6);
        var f = (hue * 6) - i;
        var p = value * (1 - saturation);
        var q = value * (1 - (saturation * f));
        var t = value * (1 - (saturation * (1 - f)));
        switch (i)
        {
            case 1: red = q; green = value; blue = p; break;
            case 2: red = p; green = value; blue = t; break;
            case 3: red = p; green = q; blue = value; break;
            case 4: red = t; green = p; blue = value; break;
            case 5: red = value; green = p; blue = q; break;
            case 6: // fall through
            case 0: red = value; green = t; blue = p; break;
        }
    }
    return {r: red, g: green, b: blue};
}

function rgbToHsv(red, green, blue)
{
    var max = Math.max(Math.max(red, green), blue);
    var min = Math.min(Math.min(red, green), blue);
    var hue;
    var saturation;
    var value = max;
    if (min == max)
    {
        hue = 0;
        saturation = 0;
    }
    else
    {
        var delta = (max - min);
        saturation = delta / max;
        if (red == max)
        {
            hue = (green - blue) / delta;
        }
        else if (green == max)
        {
            hue = 2 + ((blue - red) / delta);
        }
        else
        {
            hue = 4 + ((red - green) / delta);
        }
        hue /= 6;
        if (hue < 0)
        {
            hue += 1;
        }
        if (hue > 1)
        {
            hue -= 1;
        }
    }
    return {
        h: hue,
        s: saturation,
        v: value
    };
}

// The real code begins here.
var huePositionImg = document.createElement('img');
huePositionImg.galleryImg = false;
huePositionImg.width = 35;
huePositionImg.height = 11;
huePositionImg.src = sympa.icons_url + '/position.png';
huePositionImg.style.position = 'absolute';

var hueSelectorImg = document.createElement('img');
hueSelectorImg.galleryImg = false;
hueSelectorImg.width = 35;
hueSelectorImg.height = 200;
hueSelectorImg.src = sympa.icons_url + '/h.png';
hueSelectorImg.style.display = 'block';

var satValImg = document.createElement('img');
satValImg.galleryImg = false;
satValImg.width = 200;
satValImg.height = 200;
satValImg.src = sympa.icons_url + '/sv.png';
satValImg.style.display = 'block';

var crossHairsImg = document.createElement('img');
crossHairsImg.galleryImg = false;
crossHairsImg.width = 21;
crossHairsImg.height = 21;
crossHairsImg.src = sympa.icons_url + '/crosshairs.png';
crossHairsImg.style.position = 'absolute';

function makeColorSelector(inputBox)
{
    var rgb, hsv
    
    function colorChanged()
    {
        var hex = rgbToHex(rgb.r, rgb.g, rgb.b);
        var hueRgb = hsvToRgb(hsv.h, 1, 1);
        var hueHex = rgbToHex(hueRgb.r, hueRgb.g, hueRgb.b);
        previewDiv.style.background = hex;
        inputBox.value = hex;
        satValDiv.style.background = hueHex;
        crossHairs.style.left = ((hsv.v*199)-10).toString() + 'px';
        crossHairs.style.top = (((1-hsv.s)*199)-10).toString() + 'px';
        huePos.style.top = ((hsv.h*199)-5).toString() + 'px';
    }
    function rgbChanged()
    {
        hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
        colorChanged();
    }
    function hsvChanged()
    {
        rgb = hsvToRgb(hsv.h, hsv.s, hsv.v);
        colorChanged();
    }
    
    var colorSelectorDiv = document.createElement('div');
    colorSelectorDiv.style.padding = '15px';
    colorSelectorDiv.style.position = 'relative';
    colorSelectorDiv.style.height = '275px';
    colorSelectorDiv.style.width = '250px';
    
    var satValDiv = document.createElement('div');
    satValDiv.style.position = 'relative';
    satValDiv.style.width = '200px';
    satValDiv.style.height = '200px';
    var newSatValImg = fixPNG(satValImg);
    satValDiv.appendChild(newSatValImg);
    var crossHairs = crossHairsImg.cloneNode(false);
    satValDiv.appendChild(crossHairs);
    function satValDragged(x, y)
    {
        hsv.s = 1-(y/199);
        hsv.v = (x/199);
        hsvChanged();
    }
    trackDrag(satValDiv, satValDragged)
    colorSelectorDiv.appendChild(satValDiv);

    var hueDiv = document.createElement('div');
    hueDiv.style.position = 'absolute';
    hueDiv.style.left = '230px';
    hueDiv.style.top = '15px';
    hueDiv.style.width = '35px';
    hueDiv.style.height = '200px';
    var huePos = fixPNG(huePositionImg);
    hueDiv.appendChild(hueSelectorImg.cloneNode(false));
    hueDiv.appendChild(huePos);
    function hueDragged(x, y)
    {
        hsv.h = y/199;
        hsvChanged();
    }
    trackDrag(hueDiv, hueDragged);
    colorSelectorDiv.appendChild(hueDiv);
    
    var previewDiv = document.createElement('div');
    previewDiv.style.height = '50px'
    previewDiv.style.width = '50px';
    previewDiv.style.position = 'absolute';
    previewDiv.style.top = '225px';
    previewDiv.style.left = '15px';
    previewDiv.style.border = '1px solid black';
    colorSelectorDiv.appendChild(previewDiv);
    
    function inputBoxChanged()
    {
        rgb = hexToRgb(inputBox.value, {r: 0, g: 0, b: 0});
        rgbChanged();
    }
    $(inputBox).change(inputBoxChanged);
    inputBox.size = 8;
    var inputBoxDiv = document.createElement('div');
    inputBoxDiv.style.position = 'absolute';
    inputBoxDiv.style.right = '15px';
    inputBoxDiv.style.top =
        (225 + (25 - (inputBox.offsetHeight/2))).toString() + 'px';
    inputBoxDiv.appendChild(inputBox);
    colorSelectorDiv.appendChild(inputBoxDiv);
    
    inputBoxChanged();
    
    return colorSelectorDiv;
}

function makeColorSelectors(ev)
{
    var inputNodes = document.getElementsByTagName('input');
    var i;
    for (i = 0; i < inputNodes.length; i++)
    {
        var node = inputNodes[i];
        if (node.className != 'color')
        {
            continue;
        }
        var parent = node.parentNode;
        var prevNode = node.previousSibling;
        var selector = makeColorSelector(node);
        parent.insertBefore(selector, (prevNode ? prevNode.nextSibling : null));
    }
}

$(window).on('load', makeColorSelectors);

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
            $('<a href="#" aria-hidden="true">' + sympa.closeText + '</a>');
        closeButton.on('click', function(){
            $(selector).slideUp('normal');
            return false;
        });
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

