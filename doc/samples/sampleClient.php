<?php 
// Just a simple example of a PHP SOAP client for Sympa. 
// You can check the Sympa SOAP API definition to design more complex code : http://www.sympa.org/manual/soap
//
// You need to install the php-soap module. 
// If you are on a Fedora Core server, you can run "yum install php-soap"


$soapclient->debug_flag=true;

global $userEmail;
global $md5;
global $soapServer;
$soapServer = "http://demo.sympa.org/sympa/wsdl";

$soapclient = new SoapClient($soapServer);

ob_start();

if ($_GET['viewSource']) {

  echo "<html> <body BGCOLOR=\"#ffffff\" TEXT=\"#cccccc\" LINK=\"#ff9933\" ALINK=\"#ff9933\" VLINK=\"#ff9933\"> \n";
  show_source ( __FILE__);
}else {

  echo "<html> <body BGCOLOR=\"#000099\" TEXT=\"#cccccc\" LINK=\"#ff9933\" ALINK=\"#ff9933\" VLINK=\"#ff9933\"> \n";
  if ( $_COOKIE['sympaMd5']) {
    
    // LOGOUT
    if ($_GET['logout'] == 1) {
      setcookie ("sympaMd5", "", time() - 3600);
      echo "<P ALIGN=\"center\"><FONT COLOR=\"#ff0000\">Logged out</FONT></P>\n";
    }else {  
      $md5 = $_COOKIE['sympaMd5'];
    }
    
    // LOGIN
  }elseif ($_POST['email'] && $_POST['pwd']) {
    $md5 = $soapclient->login($_POST['email'],$_POST['pwd']);
    
    if (gettype($md5) == "string") {
      $userEmail = $_POST['email'];
      
      setcookie("sympaMd5",$md5);
      
    }else {
      echo "<P ALIGN=\"center\"><FONT COLOR=\"#ff0000\">Authentication failed</FONT></P>\n";
    }
  }
  
  if (isset($userEmail)) {
    echo "<FONT COLOR=\"99ccff\">logged in as ".$userEmail."</FONT><BR>\n";
    echo "[<A HREF=\"".$_SERVER['PHP_SELF']."?logout=1\">logout</A>]\n";
    
  }else {
    echo "You need to login first?\n Use your email address and the password obtained from <a href=\"http://demo.sympa.org/sympa\">demo.sympa.org</a> :<BR><BR>\n";
    echo "<form action=\"".$_SERVER['PHP_SELF']."\" method=\"post\">
    Email:  <input type=\"text\" name=\"email\"><br>
    Password: <input type=\"password\" name=\"pwd\">
    <input type=\"submit\" name=\"submit\" value=\"Login\">
</form>
";
  }
  
  if (isset($userEmail)) {
    
    // SIGNOFF
    if ($_GET['signoff'] == 1) {
      $res = $soapclient->authenticateAndRun($userEmail,$md5,'signoff',array($_GET['list']));
      if (gettype($res) == 'array') {
	echo "<P ALIGN=\"center\"><FONT COLOR=\"#ff0000\">Unsubscription failed<BR>".$res['faultstring']." : ".$res['detail']."</FONT></P>\n";
      }else {
	echo "<P ALIGN=\"center\"><FONT COLOR=\"#99ccff\">Successfully unsubscribed</FONT></P>\n";
      }
      
      // SUBSCRIBE
    }elseif ($_GET['subscribe'] == 1) {
      $res = $soapclient->authenticateAndRun($userEmail,$md5,'subscribe',array($_GET['list']));
      if (gettype($res) == 'array') {
	echo "<P ALIGN=\"center\"><FONT COLOR=\"#ff0000\">Subscription failed<BR>".$res['faultstring']." : ".$res['detail']."</FONT></P>\n";
      }else {
	echo "<P ALIGN=\"center\"><FONT COLOR=\"#99ccff\">Successfully subscribed</FONT></P>\n";
      }
    }
    
    
    // WHICH
    echo "<BR><BR>Mailing lists you are subscribed to :<DL>\n";
    $res = $soapclient->authenticateAndRun($userEmail,$md5,'complexWhich');
    
    if (isset($res) && gettype($res) == 'array') {

      echo "<table><tr><th>listAdress</th><th>list home page</th><th>Subject</th><th>Bounce count</th><th>first bounce date</th><th>last bounce date</th><th>bounce type</th></tr>";
      foreach ($res as $list) {
	echo "<tr>";
	list ($list->listName,$list->listDomain) = explode("@",$list->listAddress);
	$subscribed[$list->listAddress] = True;
	
	echo "<td>".$list->listAddress." [<A HREF=\"".$_SERVER['PHP_SELF']."?signoff=1&list=".$list->listName."\">signoff</A>]</td><td>[<A HREF=\"".$list->homepage."\">info</A>]</td><td>".$list->subject."</td>";
	echo "<td>".$list->bounceCount."</td><td>".$list->firstBounceDate."</td><td>".$list->lastBounceDate."</td><td>".$list->bounceCode."</td></tr>";
      }
      echo "</table>";

      #foreach ($res as $list) {
#	echo "<DD>";
#	list ($list->listName,$list->listDomain) = explode("@",$list->listAddress);
	$subscribed[$list->listAddress] = True;
#	
#	echo "<P>".$list->listAddress." [<A HREF=\"".$_SERVER['PHP_SELF']."?signoff=1&list=".$list->listName."\">signoff</A>] [<A HREF=\"".$list->homepage."\">info</A>]<BR>".$list->subject."<br>";
#	echo "$list->   </P>\n";
#      }
#      echo "</DL>\n";
    }else {
      echo "<DL><DD>No subscription</DL><BR>\n";
    }
    
    // LISTS
    echo "Other mailing lists :<DL>\n";
    $res = $soapclient->authenticateAndRun($userEmail,$md5,'complexLists');
    
    if (isset($res) && gettype($res) == 'array') {
      foreach ($res as $list) {
	echo "<DD>";
	list ($list->listName,$list->listDomain) = explode("@",$list->listAddress);
	if (isset($subscribed[$list->listAddress])) {
	  next;
	}else {
	  echo "<P>".$list->listAddress." [<A HREF=\"".$_SERVER['PHP_SELF']."?subscribe=1&list=".$list->listName."\">subscribe</A>] [<A HREF=\"".$list->homepage."\">info</A>]<BR>".$list->subject." \n</P>";
	}
      }
      echo "</DL>\n";
    }else {
      echo "<DL><DD>No subscription</DL><BR>\n";
    }
    
  }
}

ob_end_flush();

unset($soapclient); 

echo "<P ALIGN=\"right\">
<TABLE WIDTH=\"100%\">
<TR><TD ALIGN=\"left\">
<I><center>This is a sample PHP interface for Sympa using SOAP (<A HREF=\"".$_SERVER['PHP_SELF']."?viewSource=1\">View source</A>)</center></I>
</TD><TD ALIGN=\"right\">
<A HREF=\"http://www.sympa.org\"><IMG BORDER=\"0\" SRC=\"http://www.sympa.org/logos/logo-sympa-150x49.gif\"></A></TD>
</TABLE>
</P>";

?>
 </body>
 </html>
