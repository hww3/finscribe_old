import Public.Web.Wiki;
import Fins;
inherit Macros.Macro;

string describe()
{
   return "Produces a weblog";
}

void evaluate(String.Buffer buf, Macros.MacroParameters params)
{
  object root;
  int limit;

// werror("EVALUATE: %O\n", params->extras->obj);

  if(params->extras->obj && !stringp(params->extras->obj))
    root = params->extras->obj;
  else
  {
    array o = params->engine->wiki->model->find("object", (["path": params->extras->obj["path"]]));
    if(sizeof(o))
      root = o[0];
  }

  params->extras->request->misc->object_is_weblog = 1;

  // we should get a limit for the number of entries to display.

  array a = params->parameters / "|";
  if(sizeof(a) && a[0] && strlen(a[0]))
    limit = (int)a[0];
  else limit = 10;

  if(!root)
  {
    buf->add("Unable to render Weblog because the weblog page location could not be determined."); 
    return;
  } 
//werror("root: %O\n", object_program(root));

  array o;

  if(params->extras && params->extras->request && params->extras->request->variables->weblog =="full")
    o = root->get_blog_entries();
  else
    o = root->get_blog_entries(limit);

  foreach(o; int i; object entry)
  {
    object t, d;
    [t, d] = params->engine->wiki->view->prep_template("space/weblogentry.phtml");


    d->add("entry", entry);
    string s = entry["current_version"]["subject"];
    if(!s || !strlen(s)) s = "No Subject";
    d->add("subject", s);

    d->add("contents", params->engine->render(entry["current_version"]["contents"], (["request": params->extras->request, "obj": entry])));

  
    buf->add(t->render(d));
  }

  if(params->extras && params->extras->request && params->extras->request->variables->weblog =="full")
    buf->add("<a href=\"?weblog=recent\">Recent Entries...</a> | ");
  else
    buf->add("<a href=\"?weblog=full\">More Entries...</a> | ");
  buf->add("<a href=\"/rss/");
  buf->add(root["path"]);
  buf->add("\">RSS Feed</a>");
}
