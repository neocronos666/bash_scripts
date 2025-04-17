function createindex(strIndex) {
var xtop = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"></head><body bgcolor="#FFFFFF"><p><a href="javascript:history.back()"><img src="back.gif" width="43" height="35" alt="Atrás" border="0"></a></p><p><img src="';
var xbot = '"></p></body></html>';

	var resultsWindow = window;
	resultsWindow.document.open();
	resultsWindow.document.write (xtop);
	resultsWindow.document.write (strIndex);
	resultsWindow.document.write (xbot);
	resultsWindow.document.close();
}