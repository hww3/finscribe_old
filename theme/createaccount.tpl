<html>
<head>
    <link rel="STYLESHEET" type="text/css" href="/space/themes/default/default.css" />
<title>Login</title>
</head>
<body>
{include:tagline.tpl}
{include:pagebegin.tpl}
   <h3>Create account</h3>

   <p>
       {foo}
<form action="" method="post">
<input type="hidden" name="return_to" value="{return_to}"/>
Your name: <input type="string" name="Name" value="{Name}"/><br/>
Username: <input type="string" name="UserName" value="{UserName}"/><br/>
Email: <input type="string" name="Email" value="{Email}"><br/>
Password: <input type="password" name="Password" value="{Password}"/><br/>
Re-type Password: <input type="password" name="Password2"/>
<p/>
<input type="submit" name="action" value="Create"/>
<input type="submit" name="action" value="Cancel"/>
</form>
<p/>
{include:footer.tpl}
