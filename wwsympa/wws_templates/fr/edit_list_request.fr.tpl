<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM ACTION="[path_cgi]" METHOD="POST">
<INPUT TYPE="hidden" NAME="serial" VALUE="[serial]">
<TABLE WIDTH="100%" BORDER=0 CELLPADDING="0" CELLSPACING="0">
[FOREACH p IN param]
 [IF p->may_edit<>hidden]
  <TR VALIGN="top">


  [IF p->changed=1]
    <TH WIDTH="100%" BGCOLOR="--ERROR_COLOR--">
  [ELSE]
    <TH WIDTH="100%" BGCOLOR="--DARK_COLOR--">
  [ENDIF]

   <TABLE WIDTH="100%" BGCOLOR="--SELECTED_COLOR--" CELLPADDING="1" CELLSPACING="1"> 
  <TR><TH ALIGN="left" WIDTH="90%">
   <FONT SIZE="-1" COLOR="--BG_COLOR--">
    [IF p->title]
      [p->title] 
      [IF is_listmaster]      
        ([p->name])
      [ENDIF]
    [ELSE]
      [p->name]
    [ENDIF]
   </FONT>
  [IF is_listmaster]
    [IF p->default=1]
      (default)
    [ENDIF]
  [ENDIF]
  </TH><TH BGCOLOR="--LIGHT_COLOR--">
  <A HREF="[path_cgi]/help/editlist#[p->name]" onClick="window.open('','wws_help','toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,copyhistory=no,width=400,height=200')" TARGET="wws_help"  ><FONT SIZE="-1">Help</FONT></A>
  </TH></TR></TABLE>

  </TH></TR>

  <TR><TD VALIGN="top">

  <DL>
  [IF p->occurrence=multiple]
  <!-- Multiple params -->

     [FOREACH o IN p->value]
     <!-- Foreach occurrence -->
	<DD>

	[IF p->type=paragraph]
	<!-- Paragraph -->
      	  [FOREACH key IN o->value]
	    [IF key->may_edit<>hidden]
 	      [IF key->title]
	        <B>[key->title] :</B>
	      [ELSE]
	        <B>[key->name] :</B> 
	      [ENDIF]

	      [IF key->type=enum]
	      <!-- Enum -->
                [IF key->may_edit=write]
		  <SELECT NAME="single_param.[p->name].[o->INDEX].[key->name]">
	            [FOREACH enum IN key->value]
	             <OPTION VALUE="[enum->NAME]"
	             [IF enum->selected=1]
		       SELECTED
	             [ENDIF]
	             >[enum->NAME]
	            [END]
	          </SELECT>
	        [ELSIF key->may_edit=read]
	          [FOREACH enum IN key->value]
	            [IF enum->selected=1]
	              [enum->NAME]
		      <INPUT TYPE="hidden" NAME="single_param.[p->name].[o->INDEX].[key->name]" VALUE="[enum->NAME]">
	            [ENDIF]
	          [END]
	        [ENDIF]

	      [ELSE]
	      <!-- Scalar -->
                [IF key->may_edit=write]
	          <INPUT NAME="single_param.[p->name].[o->INDEX].[key->name]" VALUE="[key->value]" SIZE="[key->length]">
	        [ELSIF key->may_edit=read]
	          [key->value]
		  <INPUT TYPE="hidden" NAME="single_param.[p->name].[o->INDEX].[key->name]" VALUE="[key->value]">
	        [ENDIF]
	        [key->unit]
	      [ENDIF]
              <BR>
	    [ENDIF]
          [END]
          <HR>

	[ELSIF p->type=enum]
	<!-- Enum -->
	  [IF p->may_edit=write]
	    <SELECT NAME="single_param.[p->name].[o->INDEX]">
	     [FOREACH enum IN o->value]
	       <OPTION VALUE="[enum->NAME]"
	       [IF enum->selected=1]
		 SELECTED
	       [ENDIF]
	       [IF enum->title]
		 >[enum->title]
	       [ELSE]
	         >[enum->NAME]
	       [ENDIF]
	     [END]
	     </SELECT>
	  [ELSIF p->may_edit=read]
	    [FOREACH enum IN o->value]
	      [IF enum->selected=1]
	        [enum->NAME]
	      [ENDIF]
	    [END]
	  [ENDIF]

	[ELSE]
	<!-- Scalar -->

	  [IF p->may_edit=write]
	    <INPUT NAME="single_param.[p->name].[o->INDEX]" VALUE="[o->value]" size="[o->length]">
	  [ELSIF p->may_edit=read]
	    [o->value]
	  [ENDIF]
	  [o->unit]
	[ENDIF]
        <BR>
     [END]
     <!-- END Foreach occurrence -->

  [ELSE]
  <!-- Single params -->
    <DD>
    [IF p->type=scenario]
    <!-- Scenario -->
      [IF p->may_edit=write]
	<SELECT NAME="single_param.[p->name].name">
	  [FOREACH scenario IN p->value]
	  <OPTION VALUE="[scenario->name]"
	     [IF scenario->selected=1]
		SELECTED
	     [ENDIF]
	  >[scenario->title] ([scenario->name])
	  [END]
	</SELECT>
      [ELSIF p->may_edit=read]
	[FOREACH scenario IN p->value]
	  [IF scenario->selected=1]
	    [scenario->title] ([scenario->name])
	  [ENDIF]
	[END]
      [ENDIF]

    [ELSIF p->type=paragraph]
    <!-- Paragraph -->
      [FOREACH key IN p->value]
        [IF key->may_edit<>hidden]
	  [IF key->title]
	    <DD><B>[key->title] :</B> 
	  [ELSE]
	    <DD><B>[key->name] :</B> 
	  [ENDIF]

	  [IF key->type=scenario]
	  <!-- Scenario -->
	    [IF key->may_edit=write]
	      <SELECT NAME="single_param.[p->name].[key->name].name">
	        [FOREACH scenario IN key->value]
	          <OPTION VALUE="[scenario->name]"
	          [IF scenario->selected=1]
		    SELECTED
	          [ENDIF]
	          >[scenario->title] ([scenario->name])
	        [END]
	      </SELECT>
	    [ELSIF key->may_edit=read]
	      [FOREACH scenario IN key->value]
	        [IF scenario->selected=1]
		  [scenario->title] ([scenario->name])
	        [ENDIF]
	      [END]
	    [ENDIF]

	  [ELSIF key->type=enum]
	  <!-- Enum -->
	    [IF key->may_edit=write]
	      [IF key->occurrence=multiple]
	        <SELECT NAME="multiple_param.[p->name].[key->name]" MULTIPLE>
	      [ELSE]
	        <SELECT NAME="single_param.[p->name].[key->name]">
	      [ENDIF]
	      [FOREACH enum IN key->value]
	        <OPTION VALUE="[enum->NAME]"
	        [IF enum->selected=1]
	  	  SELECTED
	        [ENDIF]
	        [IF enum->title]
	          >[enum->title]
	        [ELSE]
	          >[enum->NAME]
	        [ENDIF]
	      [END]
	      </SELECT>
	    [ELSIF key->may_edit=read]
	      [FOREACH enum IN key->value]
	        [IF enum->selected=1]
		  [IF enum->title]
		    [enum->title] 
	  	  [ELSE]
		    [enum->NAME]
		  [ENDIF]
	        [ENDIF]
	      [END]
	    [ENDIF]

	  [ELSE]
	  <!-- Scalar -->
	    [IF p->may_edit=write]
	      <INPUT NAME="single_param.[p->name].[key->name]" VALUE="[key->value]" size="[key->length]">
	      [ELSIF p->may_edit=read]
	        [key->value]
	      [ENDIF]
	      [key->unit]
	      <BR>
	  [ENDIF]
        [ENDIF]
      [END]

    [ELSIF p->type=enum]
    <!-- Enum -->
        [IF p->may_edit=write]
	  <SELECT NAME="single_param.[p->name]">
	   [FOREACH enum IN p->value]
	   <OPTION VALUE="[enum->NAME]"
	      [IF enum->selected=1]
		 SELECTED
	      [ENDIF]
             [IF enum->title]
	       >[enum->title]
	     [ELSE]
	       >[enum->NAME]
	     [ENDIF]
	   [END]
	   </SELECT>
	[ELSIF p->may_edit=read]
	  [FOREACH enum IN p->value]
	    [IF enum->selected=1]
	      [enum->NAME]
	    [ENDIF]
	  [END]
	[ENDIF]
    [ELSE]
    <!-- Scalar -->
        [IF p->may_edit=write]
	  <INPUT NAME="single_param.[p->name]" VALUE="[p->value]" size="[p->length]">
	[ELSIF p->may_edit=read]
	  [p->value]
	[ENDIF]
	[p->unit]
    [ENDIF]
  [ENDIF]

  </DL>

  [IF p->default=1]
    <FONT COLOR="--BG_COLOR--"><B>default</B></FONT>
  [ENDIF]


  </TD>


</TR>
 [ENDIF]
[END]
</TABLE>
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
<INPUT TYPE="submit" NAME="action_edit_list" VALUE="Mise à jour">
</FORM>



