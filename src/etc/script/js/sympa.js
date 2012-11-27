function showMDN(el) {
  var pre = el.parentNode.getElementsByTagName('pre');
  if(!pre) return;
  var mdn = pre[0].innerHTML;
  return showMessage(mdn.replace(/ /g, '&nbsp;').replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;').replace(/\n/g, '<br />'), true);
}

function showMessage(message, ishtml) { // if ishtml not set then \n to <br /> transformation is applied to message
  if(!ishtml) message = message.replace(/\n/g, '<br />');
  var body = document.getElementsByTagName('body')[0];
  if(!body) return;
  
  var block = document.createElement('div');
  block.id = 'ErrorBlock';
  body.insertBefore(block, body.childNodes[0]);
  
  var msg = document.createElement('div');
  msg.id = 'ErrorMsg';
  body.insertBefore(msg, body.childNodes[0]);
  
  var ctn = document.createElement('div');
  ctn.className = 'messageContent';
  msg.appendChild(ctn);
  
  if(message) ctn.innerHTML = message;
  
  var form = document.createElement('form');
  msg.appendChild(form);
  
  var fs = document.createElement('fieldset');
  form.appendChild(fs);
  
  var cls = document.createElement('input');
  cls.type = 'button';
  cls.className = 'MainMenuLinks';
  cls.value = 'OK';
  cls._body = body;
  cls._block = block;
  cls._msg = msg;
  cls.onclick = function() {
    this._body.removeChild(this._block);
    this._body.removeChild(this._msg);
  };
  fs.appendChild(cls);
  
  return ctn;
}

// To confirm archives deletion
function dbl_confirm(my_form, my_message,my_message2) {
  if (confirm(my_message)) {
      if (confirm(my_message2)) {
        my_form.zip.value = "1";
      }
  }else{
    return false;
  }
}

// To confirm on a link (A HREF)
function refresh_mom_and_die() {
  url = window.opener.location.href;
  if (url.indexOf('logout') > -1 ) {
    url = path_cgi;
  }
  window.opener.location = url;
  self.close();
}

function setnsubmit(element,attribute,value,formid) {
	elt =  document.getElementById(element);
	elt.setAttribute(attribute,value);
	form=document.getElementById(formid);
	form.submit();
}

function showhide(div){
    oDiv = document.getElementById(div);
    if(oDiv.style.display == "none"){
        oDiv.style.display = "block";
    }else{
        oDiv.style.display = "none";
    }
}

function show(div){
    oDiv = document.getElementById(div);
    oDiv.style.display = "block";
}

function hide(div){
    oDiv = document.getElementById(div);
    oDiv.style.display = "none";
}

function hideError()
{
  document.getElementById('ErrorBlock').style.display = 'none';
  document.getElementById('ErrorMsg').style.display = 'none';
}

// To confirm a form submition
function request_confirm(my_message) {
  if (confirm(my_message)) {
    return true;
  }else {
    return false;
  } 
}

// To confirm on a link (A HREF)
function request_confirm_link(my_url, my_message) {
  question = confirm(my_message);
  if (question !="0") {
       top.location = my_url;
  }
}

function GetCookie (name) {
   var arg = name + "=";
   var alen = arg.length;
   var clen = document.cookie.length;
   var i = 0;
   while (i < clen) {
     var j = i + alen;
     if (document.cookie.substring(i, j) == arg) 
       return getCookieVal (j);
       i = document.cookie.indexOf(" ", i) + 1;
       if (i == 0) break; 
     }
   return null;
}  

function getCookieVal (offset) {
  var endstr = document.cookie.indexOf (";", offset);
  if (endstr == -1)
    endstr = document.cookie.length;
  return unescape(document.cookie.substring(offset, endstr));
}

function toggle_selection(myfield) {
  if (!myfield.length) {
     if (myfield.checked) {
       myfield.checked = false;
     }else {
   myfield.checked = true;
     }
  }else if (myfield.length){
    for (i = 0; i < myfield.length; i++) {
       if (myfield[i].checked) {
         myfield[i].checked = false;
       }else {
         myfield[i].checked = true;
       }
    }
  }
}

function chooseColorNumber(cn) {
    var select = document.getElementById('custom_color_number');

    if(select) for(var i=0; i<select.options.length; i++) if(select.options[i].value == cn) select.options.selectedIndex = i;
 }

// check if rejecting quietly spams
 function check_reject_spam(form,warningId) {

    if (form.elements['iConfirm'].checked) {
	return (true);
    }
    if ( form.elements['message_template'].options[form.elements['message_template'].selectedIndex].value ==  'reject_quiet' ){
	return (true);
    }	
    document.getElementById(warningId).style.display = 'block';	
    return (false);
}


// To check at least one checkbox checked
function checkbox_check_topic(form,warningId) {
 
    var checkbox_checked = false;
    var expr = /^topic_/;	
  
    for (i = 0; i < form.elements.length; i++) {
      if (form.elements[i].type == "checkbox") { 
        var box = form.elements[i];
        if (box.checked == "1" && expr.test(box.name)) {
 	 checkbox_checked = true;
       	 break;	
        }
      }
    }
    if (checkbox_checked) {
      	return(true);	
    } else {
	document.getElementById(warningId).style.display='block';
        return(false);
    }
}

function set_select_value(s, v) {
	for(var i=0; i<s.options.length; i++) s.options[i].selected = false;
	for(var i=0; i<s.options.length; i++) if(s.options[i].value == v) {
		s.options[i].selected = true;
		return;
	}
}

//launch a search by message Id
function searched_by_msgId(id) {
	var f = document.forms["log_form"];
	
	set_select_value(f.elements["type"], 'all_actions');
	
	set_select_value(f.elements["target_type"], 'msg_id');
	
	f.elements["target"].value = id;
	f.submit();
}
function searched_by_target(target_type, target) {
	var f = document.forms["log_form"];

	set_select_value(f.elements["type"], 'all_actions');

	set_select_value(f.elements["target_type"], target_type);

	f.elements["target"].value = target;
	f.submit();
}


//reset all field in log form.
function clear_log_form() {
	var f = document.forms["log_form"];
	
	set_select_value(f.elements["type"], 'all_actions');
	
	set_select_value(f.elements["target_type"], 'msg_id');
	
	f.elements["target"].value = '';

	f.elements["date_from"].value = '';
	f.elements["date_to"].value = '';
	f.elements["ip"].value = '';
}

//set a form field value to empty string. It uses the value of the field whose id is given
// as argument as a control to perform this operation or not.
function empty_field(target_field, control_field) {
	if (document.getElementById(control_field).value == 'false'){
		document.getElementById(control_field).value = 'true';
		document.getElementById(target_field).value = '';
	}
}

//to hide menu

function afficheId(baliseId,baliseId2)
  {
  if (document.getElementById && document.getElementById(baliseId) != null)
    {
    document.getElementById(baliseId).style.visibility='visible';
    document.getElementById(baliseId).style.display='block';
    }
  if (document.getElementById(baliseId2) != null)
    {
    document.getElementById(baliseId2).style.margin='0 0 0 25%';
    }
  }

function cacheId(baliseId,baliseId2)
  {
  if (document.getElementById && document.getElementById(baliseId) != null)
    {
    document.getElementById(baliseId).style.visibility='hidden';
    document.getElementById(baliseId).style.display='none';
    }
  if (document.getElementById(baliseId2) != null)
    {
    document.getElementById(baliseId2).style.margin='0 0 0 0';
    }
  
  }

cacheId('contenu','Stretcher');
// if JavaScript is available, hide the content on the page load.
// Without JavaScript, content will be display.


// Pour afficher/cacher avec timeout des commandes d'admin dans la liste des listes
function affiche(id) {
  document.getElementById(id).style.display = '';
  if(document.getElementById(id).to) window.clearTimeout(document.getElementById(id).to);
}
function cache(e,id) {
  var relTarg = e.relatedTarget || e.toElement;
  if(!isChildOf(relTarg,document.getElementById('admin_[% listname %]'))) {
    document.getElementById(id).to = window.setTimeout(function() {
      document.getElementById(id).style.display = 'none';
    }, 1000);
  }
}
function isChildOf(child,par) {
  while(child!=document) {
    if(child==par) { return true; }
    child = child.parentNode;
  }
  return false;
}
// Fin afficher/cacher avec timeout des commandes d'admin dans la liste des listes



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
    function fixCoords(x, y)
    {
        var nodePageCoords = pageCoords(node);
        x = (x - nodePageCoords.x) + document.documentElement.scrollLeft;
        y = (y - nodePageCoords.y) + document.documentElement.scrollTop;
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x > node.offsetWidth - 1) x = node.offsetWidth - 1;
        if (y > node.offsetHeight - 1) y = node.offsetHeight - 1;
        return {x: x, y: y};
    }
    function mouseDown(ev)
    {
        var coords = fixCoords(ev.clientX, ev.clientY);
        var lastX = coords.x;
        var lastY = coords.y;
        handler(coords.x, coords.y);

        function moveHandler(ev)
        {
            var coords = fixCoords(ev.clientX, ev.clientY);
            if (coords.x != lastX || coords.y != lastY)
            {
                lastX = coords.x;
                lastY = coords.y;
                handler(coords.x, coords.y);
            }
        }
        function upHandler(ev)
        {
            myRemoveEventListener(document, 'mouseup', upHandler);
            myRemoveEventListener(document, 'mousemove', moveHandler);
            myAddEventListener(node, 'mousedown', mouseDown);
        }
        myAddEventListener(document, 'mouseup', upHandler);
        myAddEventListener(document, 'mousemove', moveHandler);
        myRemoveEventListener(node, 'mousedown', mouseDown);
        if (ev.preventDefault) ev.preventDefault();
    }
    myAddEventListener(node, 'mousedown', mouseDown);
    node.onmousedown = function(e) { return false; };
    node.onselectstart = function(e) { return false; };
    node.ondragstart = function(e) { return false; };
}

var eventListeners = [];

function findEventListener(node, event, handler)
{
    var i;
    for (i in eventListeners)
    {
        if (eventListeners[i].node == node && eventListeners[i].event == event
         && eventListeners[i].handler == handler)
        {
            return i;
        }
    }
    return null;
}
function myAddEventListener(node, event, handler)
{
    if (findEventListener(node, event, handler) != null)
    {
        return;
    }

    if (!node.addEventListener)
    {
        node.attachEvent('on' + event, handler);
    }
    else
    {
        node.addEventListener(event, handler, false);
    }

    eventListeners.push({node: node, event: event, handler: handler});
}

function removeEventListenerIndex(index)
{
    var eventListener = eventListeners[index];
    delete eventListeners[index];
    
    if (!eventListener.node.removeEventListener)
    {
        eventListener.node.detachEvent('on' + eventListener.event,
                                       eventListener.handler);
    }
    else
    {
        eventListener.node.removeEventListener(eventListener.event,
                                               eventListener.handler, false);
    }
}

function myRemoveEventListener(node, event, handler)
{
    removeEventListenerIndex(findEventListener(node, event, handler));
}

function cleanupEventListeners()
{
    var i;
    for (i = eventListeners.length; i > 0; i--)
    {
        if (eventListeners[i] != undefined)
        {
            removeEventListenerIndex(i);
        }
    }
}
myAddEventListener(window, 'unload', cleanupEventListeners);

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

function pageCoords(node)
{
    var x = node.offsetLeft;
    var y = node.offsetTop;
    var parent = node.offsetParent;
    while (parent != null)
    {
        x += parent.offsetLeft;
        y += parent.offsetTop;
        parent = parent.offsetParent;
    }
    return {x: x, y: y};
}

// The real code begins here.
var huePositionImg = document.createElement('img');
huePositionImg.galleryImg = false;
huePositionImg.width = 35;
huePositionImg.height = 11;
huePositionImg.src = HUE_SLIDER_ARROWS_LOCATION;
huePositionImg.style.position = 'absolute';

var hueSelectorImg = document.createElement('img');
hueSelectorImg.galleryImg = false;
hueSelectorImg.width = 35;
hueSelectorImg.height = 200;
hueSelectorImg.src = HUE_SLIDER_LOCATION;
hueSelectorImg.style.display = 'block';

var satValImg = document.createElement('img');
satValImg.galleryImg = false;
satValImg.width = 200;
satValImg.height = 200;
satValImg.src = SAT_VAL_SQUARE_LOCATION;
satValImg.style.display = 'block';

var crossHairsImg = document.createElement('img');
crossHairsImg.galleryImg = false;
crossHairsImg.width = 21;
crossHairsImg.height = 21;
crossHairsImg.src = CROSSHAIRS_LOCATION;
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
    myAddEventListener(inputBox, 'change', inputBoxChanged);
    inputBox.size = 8;
    inputBox.style.position = 'absolute';
    inputBox.style.right = '15px';
    inputBox.style.top = (225 + (25 - (inputBox.offsetHeight/2))).toString() + 'px';
    colorSelectorDiv.appendChild(inputBox);
    
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

myAddEventListener(window, 'load', makeColorSelectors);

/***********************************************************************
* script MICRO-CAL (V4.2) par Amroune Selim (amrounix@gmail.com)
* all copies, releases, modifications or improvements are allowed.
************************************************************************
* Using script to manage the calendar.
* Used by suspend_request.tt2
* Select a start date and end date.
*************************************************************************/
/* simplification calls */
function _(x) 
{
  return document.getElementById(x);
}

/* Returns the number of days since January 1 (for number of the week)*/
function nbJ(dateX) 
{
  var j_mois=[0,31,59,90,120,151,181,212,243,273,304,334];
  mm=dateX.getMonth();aa=dateX.getFullYear();nb=j_mois[mm]+dateX.getDate()-1 ;
  if ((aa%4==0 && aa %100!=0 || aa%400==0) && mm>1) nb++; /*test bissextile*/
  return nb;
}

function dateMin(dateA,dateB)
{
  return (dateB==null||(dateA!=null&&(dateA.getFullYear()<dateB.getFullYear()
				      ||(dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()<dateB.getMonth())
				      ||(dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()==dateB.getMonth()&&dateA.getDate()<dateB.getDate())
				      ))) ? dateA:dateB
    }

function dateMax(dateA,dateB)
{
  return (dateB==null||(dateA!=null&&(dateA.getFullYear()>dateB.getFullYear()
				      ||(dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()>dateB.getMonth())
				      ||(dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()==dateB.getMonth()&&dateA.getDate()>dateB.getDate())
				      ))) ? dateA:dateB
    }

/* compare two dates and return true if dateA<=dateB */
function dateBefore(dateA,dateB) 
{
  return dateA!=null&&dateB!=null&&(dateA.getFullYear()<dateB.getFullYear()||(dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()<dateB.getMonth())||
				    (dateA.getFullYear()==dateB.getFullYear()&&dateA.getMonth()==dateB.getMonth()&&dateA.getDate()<dateB.getDate()));
}

/* function to display the navigation informations */
function htmNavChk(dateA,dateB,src,srcId,mm,yy,txt) 
{
  return (dateBefore(dateA,dateB)) ? 
    "<td onclick=\"\">&nbsp;</td>" : ("<td class=\"zoneNav\" onclick=\"return generateCal('"+src+"','"+srcId+"',"+mm+","+yy+")\">"+txt+"</td>");
}

/* create the calendar */
function generateCal(src,srcId,mm,yy) 
{
  if (tempo!=null&&tempo[srcId]!=null)
    {
      clearTimeout(tempo[srcId]);
      _(src).focus();
    }
  
  if (mm<0) {mm+=12;yy--;} /*changement de mois/année*/
  else if (mm>11) {mm-=12;yy++;}
  
  dnow=new Date(); /*date du jour*/
  param=_(srcId).parametre; /*parametre par defaut*/
  ddeb = null; dfin = null;
  
  if (param["ddeb"]!="" && _(param["ddeb"]+"_cal")!=null && _(param["ddeb"]+"_cal").parametre.date != null)
    ddeb = _(param["ddeb"]+"_cal").parametre.date;
  if (param["dfin"]!="" && _(param["dfin"]+"_cal")!=null && _(param["dfin"]+"_cal").parametre.date != null)
    dfin = _(param["dfin"]+"_cal").parametre.date;
  
  htm="<table cellpadding=0 cellspacing=0 >";
  
  /*titre*/
  if (param["titre"]!= null )
    {htm+="<tr><td colspan=\"8\" class=\"zoneTitre\" >"+param["titre"]+"</td></tr>";}
  
  /*navigation area*/
  htm+="<tr><td colspan=\"8\"><table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" ><tr>";
  htm+=htmNavChk(new Date(yy-1,mm,1),dateMax(ddeb,param["dateMin"]),src,srcId,mm,yy-1,param["anneeMoins"]);
  htm+=htmNavChk(new Date(yy,mm,0),dateMax(ddeb,param["dateMin"]),src,srcId,mm-1,yy,param["moisMoins"]);
  htm+="<td class=\"zoneMois\">"+param["mois"][mm]+"</td>";
  htm+=htmNavChk(dateMin(dfin,param["dateMax"]),new Date(yy,mm+1,1),src,srcId,mm+1,yy,param["moisPlus"]);
  htm+=htmNavChk(dateMin(dfin,param["dateMax"]),new Date(yy+1,mm,1),src,srcId,mm,yy+1,param["anneePlus"]);
  htm+="</tr></table></td></tr>";
  
  /* day of the week*/
  htm+="<tr><td></td>";
  pJs = param["debutSemaine"];
  pJm = new Date(yy,mm,1).getDay(); /*day of the 1st of the month*/
  pjT = 1-pJm+pJs;
  pjT-=(pjT>1)?7:0;
  dateX = new Date(yy,mm,pjT);
  for (j=0;j<7;j++)                 /*display the days of the week*/
    {
      htm+="<td>"+param["jour"][(j+pJs)%7]+"</td>";
    }
  htm+="</tr>";
  avantFinMois=true;idx=0;
  idxSem=parseInt(nbJ(new Date(yy,mm,1))/7+1,10); /*index de la semaine*/
  
  while(avantFinMois) /*loop until the end month */
    {
      /* If we want to display the number of weeks : htm+=(idx%7==0)?"<tr><td class=\"nSemaine\" >"+idxSem+"</td>":""; */
	htm+=(idx%7==0)?"<tr><td class='nSemaine' >"+""+"</td>":""; /* delete the number of weeks*/
      if (dateBefore(dateX,dateMax(ddeb,param["dateMin"]))||dateBefore(dateMin(dfin,param["dateMax"]),dateX))
	htm+="<td style=\"text-decoration:line-through;\"><a class=\"tdx\" href=\"#\">"+subDiv(param,idx,dateX,mm,aa,0)+"</b></td>";
      else
	htm+="<td><a class=\"tdx\" href=\"#\" onclick=\"javascript:choix("+dateX.getFullYear()+","+dateX.getMonth()+","+dateX.getDate()+",'"+srcId+"','"+src+"')\" >"+subDiv(param,idx,dateX,mm,aa,0)+"</a></td>";
      idx++;
      if (idx%7==0)
	{htm+="</tr>"; idxSem++;}
      dateX= new Date(dateX.getFullYear(),dateX.getMonth(),dateX.getDate()+1);
      if (idx>7&&idx%7==0&&dateX.getMonth()!=mm)
	{avantFinMois=false;}
    }
  htm+="<tr><td colspan='6'>&nbsp;&nbsp;";
  if (!dateBefore(dnow,dateMax(ddeb,param["dateMin"]))&&!dateBefore(dateMin(dfin,param["dateMax"]),dnow))
    htm+="<a class=\"tdxNow\" href=\"#\" onclick=\"javascript:choix("+dnow.getFullYear()+","+dnow.getMonth()+","+dnow.getDate()+",'"+srcId+"','"+src+"')\" >"+param["aujourdhui"]+"</a>";
  else htm+="&nbsp;"
    
    /*year*/
    htm+="</td><td colspan=\"2\" class=\"zoneAnnee\">"+yy+"</td></tr></table>";
  //alert(htm);
  _(srcId).innerHTML=htm;
  return false;
}

/* add a zero before */
function addZero(val) 
{ return ((val<10)?"0":"")+val;}

function choix(aa,mm,jj,srcId,src)
{
  var datePos=new Date(aa,mm,jj);
  var jour = datePos.getDay();
  param=_(srcId).parametre;
  param.date = datePos;
  var dateAffiche = param["format"].replace("%j",addZero(datePos.getDate())).replace("%k",datePos.getDate()).replace("%d",param["jLib"][jour]);
  dateAffiche = dateAffiche.replace("%m",addZero(datePos.getMonth()+1)).replace("%n",datePos.getMonth()+1).replace("%p",param["mois"][datePos.getMonth()]);
  dateAffiche = dateAffiche.replace("%a",datePos.getFullYear()).replace("%y",datePos.getYear());
  _(src).value = dateAffiche;
}

function subDiv(param,idx,dateX,mm,aa,code)
{
  pJs = param["debutSemaine"];
  dnow=new Date();
  switch(code)
    {
    case 0 : return (param["jPause"][(idx+pJs)%7]==true) ? "<div class=\"enWeekEnd\" >"+subDiv(param,idx,dateX,mm,aa,1)+"</div>" : subDiv(param,idx,dateX,mm,aa,1) ; break;
    case 1 : return (param["jFeriee"][dateX.getDate()+"-"+(dateX.getMonth()+1)]!=null) ? ("<div class=\"enFeriee\" title=\""+param["jFeriee"][dateX.getDate()+"-"+(dateX.getMonth()+1)]+"\" >"+subDiv(param,idx,dateX,mm,aa,2)+"</div>") : subDiv(param,idx,dateX,mm,aa,2) ; break;
    case 2 : return (dateX.getMonth()==mm) ? "<div class=\"enMois\" >"+subDiv(param,idx,dateX,mm,aa,3)+"</div>" : subDiv(param,idx,dateX,mm,aa,3) ; break;
    case 3 : return (dateX.getMonth()==dnow.getMonth()&&dateX.getFullYear()==dnow.getFullYear()&&dateX.getDate()==dnow.getDate()) ? "<div class=\"aujourdhui\" >"+subDiv(param,idx,dateX,mm,aa,4)+"</div>" : subDiv(param,idx,dateX,mm,aa,4) ; break;
    case 4 : return dateX.getDate(); break;
    }
}

function getMinx(tab,mini)
{
  var rc=mini,code="";
  for (k in tab)
    {
      if (tab[k]>mini && rc<tab[k]) {rc=tab[k]; code = k; }
    }
  return code;
}

function decodeDate(val,format,defaut)
{
  var dnow = defaut,jj= dnow.getDate(),mm = dnow.getMonth(), aa= dnow.getFullYear();
  var parx = {"%j":"([0123][0-9])","%k":"([0123]?[0-9])","%d":"("+(param["jLib"].join("|"))+")","%m":"([01][0-9])","%n":"([01]?[0-9])",
	      "%p":"("+(param["mois"].join("|"))+")","%a":"([12][0-9]{3})","%y":"([0-9]{2})"};
  var ff= format,df = format;
  for (e in parx)
    {
      ff = ff.replace(e,parx[e]);
      df = df.replace(e,"("+e+")");
    }
  tablo = (new RegExp(ff)).exec(val);
  clef = (new RegExp(df)).exec(format);
  if (tablo!=null&&clef!=null)
    {
      for (i = 0; i< tablo.length;i++)
	{
	  switch(clef[i])
	    {
	    case "%j": case "%k" : jj=parseInt(tablo[i],10); break;
	    case "%m": case "%n" : mm=parseInt(tablo[i],10)-1; break;
	    case "%p" : mm=0; while(mm<param["mois"].length&&param["mois"][mm]!=tablo[i]){mm++;};  break;
	    case "%a": aa = parseInt(tablo[i],10); break;
	    }
	}
    }
  return new Date(aa,mm,jj);
}

/* Initialisation of the parameters for the calendar : display position, create div, ... */
/* Let you see the calendar when you click on the input */
function visuCal(src,paramX)
{
  if (src.id=="")         /*if not ID, create one*/
    {
      cpt=0;
      while(_("microcal"+cpt) != null) 
	{cpt++;}
      src.id="microcal"+cpt;
    }
  pos_ = new Array();
  pos_ = getOffsets(_(src.id)); 
  srcId = src.id+"_cal";  /*id div for calendar*/
  dnow= new Date();
  if (_(srcId)==null)     /*if doesn't exist create one*/
    {
      param={}
      for (e in pDefaut) {
	trouve=false;
	if (paramX!=null)
	  for (i in paramX) { if (e==i) {param[e]=paramX[e];trouve=true;} }
	if (!trouve) param[e]=pDefaut[e];
      }
      dnow = decodeDate(src.value,param.format,new Date()); 
      div = document.createElement('div');
      div.setAttribute('id',srcId);
      div.style.position = 'absolute';
      div.style.top = (pos_[1] + 18) + 'px'; /* 18 : high of the input */
      div.style.left = pos_[0] + 'px';  /*this.deltaG = 0; */
      div.className = 'divCal';
      div.parametre = param;
      document.body.appendChild(div);
      generateCal(src.id,srcId,dnow.getMonth(),dnow.getFullYear(),param);
    } else
    {
      div = _(src.id+"_cal");
      div.style.display='inline';      /*display calendar*/
      div.style.top = (pos_[1] + 18) + 'px'; 
      div.style.left = pos_[0] + 'px';  /*this.deltaG = 0; */
    }
  
}

/* hide the calendar  */
function masqueCal(src)
{
  tempo[src.id+"_cal"]=window.setTimeout("_('"+src.id+"_cal').style.display='none'",500);
}

/* return the position (x, y) of an element in an array */
function getOffsets(obj) {
    var offsetTop = obj.offsetTop;
    var offsetLeft = obj.offsetLeft;
    while ((obj = obj.offsetParent )!=null) {
        offsetTop += obj.offsetTop;
        offsetLeft += obj.offsetLeft;
    }
    return [offsetLeft, offsetTop];
}

/* popups config contextual help */
function config_ctxhelp(td) {
	if(!td.d) {
		var tbl = td;
		var d = td.getElementsByTagName('div')[0];
		while(tbl.parentNode && tbl.tagName.toLowerCase() != 'table') tbl = tbl.parentNode;
		if(tbl.tagName.toLowerCase() == 'table') d.style.width = tbl.offsetWidth + 'px';
		td.d = d;
		td.onmouseout = function() {
			this.d.style.display = 'none';
		}
	}
	td.d.style.display = 'block';
}


// function that hide all hiddenform except one which Id is the function parameter (used in modindex and more)
function toggleDivDisplay(my_message_id)
{
  var divs = document.getElementsByTagName('div');
  for(var i=0; i<divs.length; i++){
     if(divs[i].getAttribute('name') != 'hiddenform') continue;
     if (divs[i].id == my_message_id) {
        if (divs[i].style.display == 'block') {
                divs[i].style.display = 'none';
        } else {
                divs[i].style.display = 'block';
        }
     } else {
        divs[i].style.display = 'none';
     }
  }
}



//hide a div (usually a part of a form) 
function hideform(my_message_id)
{
	document.getElementById(my_message_id).style.display='none';
}


// fade effect for notification boxes
jQuery(document).ready(function() {
    $('#noticeMsg').delay(500).fadeOut(4000);
  }
);

function spoolPopup(msgkey, url, trigger, remove_if_divclass_present) {
	if(!remove_if_divclass_present) remove_if_divclass_present = '';
	jQuery('.viewspool').hide();
	var p = jQuery('#viewspool' + msgkey).attr({msgkey: msgkey, ridcp: remove_if_divclass_present}).load(url, function(t, s, r) {
		var p = jQuery(this), msgkey = p.attr('msgkey'), ridcp = p.attr('ridcp');
		if(ridcp && p.has('.' + ridcp).length) {
			p.parent().delay(2000).queue(function() {
				jQuery(this).remove();
			});
			if(msgkey) jQuery('#spoolitem' + msgkey).delay(2000).queue(function() {
				jQuery(this).remove();
			});
		}
	}).parent().show();
	if(!p.parent().is('body')) {
		var pos = (trigger ? jQuery(trigger) : p.parent()).offset();
		p.detach().appendTo(jQuery('body')).css({'top': pos.top, 'left': pos.left, 'width': (jQuery('body').innerWidth() - pos.left - 100) + 'px', 'z-index': 10000});
	}
}
