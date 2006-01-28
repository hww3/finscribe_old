//<locale-token project="FinScribe">LOCALE</locale-token>

#define LOCALE(X,Y) Locale.translate(app->config->app_name, id->get_lang(), X, Y)


import Fins;
inherit Fins.FinsController;

public void index(Request id, Response response, mixed ... args)
{
  object v = view->get_view("install/wizard");

  v->add("dbs", available_dbs());
  response->set_view(v);

}

public void verifyandcreate(Request id, Response response, mixed ... args)
{
  mixed e = (catch(Sql.Sql(id->variables->dburl)));
  if(e) 
    response->set_data(((array)e)[0]);
  else response->set_data("true");
}

public void makedburl(Request id, Response response, mixed ... args)
{
  string url = "";
  if(args[0] == "SQLite")
  {
    url = sprintf("SQLite://%s", id->variables->sqlitepath);
  }
  else if(args[0] == "mysql")
  {
    url = sprintf("mysql://%s:%s@%s/%s", 
                     id->variables->mysqluser,
                     id->variables->mysqlpassword,
                     id->variables->mysqlhost,
                     id->variables->mysqldatabase);
  }

  else if(args[0] == "postgres")
  {
    url = sprintf("postgres://%s:%s@%s/%s", 
                     id->variables->postgresuser,
                     id->variables->postgrespassword,
                     id->variables->postgreshost,
                     id->variables->postgresdatabase);
  }

  response->set_data(url);
}

public void getdburlconfigurator(Request id, Response response, mixed ... 
args)
{
  if(!args || !args[0])
    response->set_data("Invalid db type.");
  else if (!(<"mysql", "postgres", "SQLite">)[args[0]])
  {
    response->set_data("Unsupported database type.");
  }
  else
  {
    object v = view->get_view("install/" + args[0]);
    response->set_view(v);
  }
}

private array available_dbs()
{
  array r = ({});


  if(haveit("Sql.Provider.SQLite"))
  {
    r += ({"SQLite"});
  }

  if(haveit("Mysql.mysql"))
  {
    r += ({"mysql"});
  }

  if(haveit("Postgres.postgres"))
  {
    r += ({"postgres"});
  }

  return r;
}

private int haveit(string sym)
{
  int x = !zero_type(all_constants()[sym]) ||
    !zero_type(master()->resolv(sym));
  return x;
}