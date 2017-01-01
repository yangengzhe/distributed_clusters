<%@ page import="java.util.*" %>  
<%@ page language="java" import="java.util.*" pageEncoding="GBK"%>  
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
<html>  
<head>  
<title>Server Info</title>  
<meta http-equiv="pragma" content="no-cache">  
<meta http-equiv="cache-control" content="no-cache">  
<meta http-equiv="expires" content="0">  
</head>  
<body>  
<%  
String SERVER_NAME = request.getServerName();  
String SERVER_ADDR = request.getLocalAddr();  
String SERVER_SOFTWARE = getServletContext().getServerInfo();  
String SERVER_PROTOCOL = request.getProtocol();  
Integer SERVER_PORT = request.getServerPort();  
String REQUEST_METHOD = request.getMethod();  
String PATH_INFO = request.getPathInfo();  
String PATH_TRANSLATED = request.getPathTranslated();  
String SCRIPT_NAME = request.getServletPath();  
String DOCUMENT_ROOT = request.getRealPath("/");  
String QUERY_STRING = request.getQueryString();  
String REMOTE_HOST = request.getRemoteHost();  
String REMOTE_ADDR = request.getRemoteAddr();  
String AUTH_TYPE = request.getAuthType();  
String REMOTE_USER = request.getRemoteUser();  
String CONTENT_TYPE = request.getContentType();  
Integer CONTENT_LENGTH = request.getContentLength();  
String HTTP_ACCEPT = request.getHeader("Accept");  
String HTTP_USER_AGENT = request.getHeader("User-Agent");  
String HTTP_REFERER = request.getHeader("Referer");  
HashMap infoMap = new HashMap();  
infoMap.put("SERVER_NAME", SERVER_NAME);  
infoMap.put("SERVER_ADDR", SERVER_ADDR);  
infoMap.put("SERVER_SOFTWARE", SERVER_SOFTWARE);  
infoMap.put("SERVER_PORT", SERVER_PORT);  
infoMap.put("DOCUMENT_ROOT", DOCUMENT_ROOT);  
infoMap.put("REMOTE_HOST", REMOTE_HOST);  
infoMap.put("REMOTE_ADDR", REMOTE_ADDR);  
infoMap.put("REMOTE_USER", REMOTE_USER);  

Iterator it = infoMap.keySet().iterator();  
%>  
<table border="1">  
<%  
while (it.hasNext()) {  
Object o = it.next();  
%>  
<tr>  
<td>  
<%=o%>  
<td>  
<%=infoMap.get(o)%>  
</td>  
</tr>  
<%  
}  
%>  
</table>  
Server Info:

<%
out.println(request.getLocalAddr() + " : " + request.getLocalPort()+"");%>
<br>
<%
  out.println("ID:" + session.getId()+"");
	out.println("<br>");  
// 如果有新的 Session 属性设置
  String dataName = request.getParameter("dataName");
  if (dataName != null && dataName.length() > 0) {
     String dataValue = request.getParameter("dataValue");
     session.setAttribute(dataName, dataValue);
  }
  out.print("Session list:<br>");
  Enumeration e = session.getAttributeNames();
  while (e.hasMoreElements()) {
     String name = (String)e.nextElement();
     String value = session.getAttribute(name).toString();
     out.println( name + " = " + value+"");
         System.out.println( name + " = " + value + "<br>");
   }
%>  
</body>  
</html>
