import Public.Parser.XML2;
import Fins;
inherit Fins.FinsController;

public void index(Request id, Response response, mixed ... args)
{
  string r;

  object obj = model()->get_fbobject(args, id);

  if(!obj) 
  {
    response->redirect("/exec/notfound/" + args*"/");
  }

  if(id->variables->type == "history")
  {
    history_rss(id, response, obj, args);
  }

  else if(id->variables->type == "comments")
  {
    comments_rss(id, response, obj, args);
  }
  
  else // blog changes is the default mode
  {
    weblog_rss(id, response, obj, args);
  }

}

private void weblog_rss(Fins.Request id, Fins.Response response,
  object obj, mixed ... args)
{
  if(obj["datatype"]["mimetype"] != "text/wiki")
  {
    response->flash("msg", "page requested is not a weblog.\n");
    response->redirect("/exec/notfound/" + args*"/");
    return;
  }
 
  array o = obj->get_blog_entries(10);

  Node n = generate_weblog_rss(obj, o, id);

  response->set_type("text/xml");
  response->set_data(render_xml(n));
}

private void comments_rss(Fins.Request id, Fins.Response response,
  object obj, mixed ... args)
{
  if(obj["datatype"]["mimetype"] != "text/wiki")
  {
    response->flash("msg", "page requested is not a wiki page.\n");
    response->redirect("/exec/notfound/" + args*"/");
    return;
  }
 
  array o = obj["comments"];

  Node n = generate_comments_rss(obj, o, id);

  response->set_type("text/xml");
  response->set_data(render_xml(n));
}

private void history_rss(Fins.Request id, Fins.Response response,
  object obj, mixed ... args)
{
  if(obj["datatype"]["mimetype"] != "text/wiki")
  {
    response->flash("msg", "page requested is not a weblog.\n");
    response->redirect("/exec/notfound/" + args*"/");
    return;
  }
 
  array o = obj->get_blog_entries(10);

//  Node n = generate_rss(obj, o, id);

  response->set_type("text/xml");
//  response->set_data(render_xml(n));
}

private Node generate_weblog_rss(object root, array entries, object id)
{
  Node n = new_xml("1.0", "rss");
  n->set_attribute("version", "2.0");

  Node c;

  c = n->new_child("channel", "");
  c->new_child("title", root["title"]);
  c->new_child("link", app()->config->get_value("site", "url"));
  c->new_child("description", "");
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");

    foreach(entries; int i; object row)
    {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/space/%s", app()->config->get_value("site", "url"), 
        row["path"]));
      item->new_child("guid",  sprintf(
        "%s/space/%s", app()->config->get_value("site", "url"),
        row["path"]))->set_attribute("isPermaLink", "1");
      item->new_child("title", row["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());
      item->new_child("description", app()->engine->render(row["current_version"]["contents"], (["request": id, "obj": row])));
    }
  return n;
}

private Node generate_comments_rss(object root, array entries, object id)
{
  Node n = new_xml("1.0", "rss");
  n->set_attribute("version", "2.0");

  Node c;

  c = n->new_child("channel", "");
  c->new_child("title", root["title"]);
  c->new_child("link", ({ app()->config->get_value("site", "url"), "space",  root["path"] }) * "/" );
  c->new_child("description", app()->engine->render(root["current_version"]["contents"], (["request": id, "obj": root])));
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");

  // we should put the entries in newest first order.
    foreach(FinScribe.Blog.limit(reverse((array)entries), 10); int i; object row)
//    foreach(entries; int i; object row)
    {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/comments/%s#%s", app()->config->get_value("site", "url"), 
        root["path"], (string)row["id"]));

      item->new_child("guid",  sprintf(
        "%s/comments/%s#%s", app()->config->get_value("site", "url"), 
        root["path"], (string)row["id"]))->set_attribute("isPermalink", "1");

      item->new_child("title", row["author"]["UserName"] + ": " + row["object"]["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());
      item->new_child("description", app()->engine->render(row["contents"], (["request": id, "obj": row])));
    }
  return n;
}

