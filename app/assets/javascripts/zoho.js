var $zoho=$zoho || {};$zoho.salesiq = $zoho.salesiq ||
{widgetcode:"36cbcdb0e160997fee1e244d7303c519d9b33f7c295d072ed32fd822580f5bbf577de32b141ccbbdde5e1297eb772ace", values:{},ready:function(){}}; var d=document;s=d.createElement("script");s.type="text/javascript";s.id="zsiqscript";s.defer=true;
s.src="https://salesiq.zoho.com/widget";t=d.getElementsByTagName("script")[0];t.parentNode.insertBefore(s,t);d.write("<div id='zsiqwidget'></div>");

$zoho.salesiq.ready=function()
{ 
	var email = '<%= current_user.email %>';
	$zoho.salesiq.visitor.email( email );
}
