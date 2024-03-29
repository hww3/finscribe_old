#if constant(Public.Parser.XML2)
import Public.Parser.XML2;
#endif /* Public.Parser.XML2 */

import Fins;
inherit Fins.FinsController;
import Fins.Model;

constant __uses_session = 0;

static void start() {
  after_filter(Fins.Helpers.Filters.Compress());
}

#if constant (Public.Parser.XML2)
public void index(Request id, Response response, mixed ... args)
{
  object obj;
  if(id->variables->type == "category")
  {
    array a = find.categories((["category": args*"/"]));
    if(!sizeof(a))
    {
      response->not_found("category " + args*"/");
      return;
    }

    obj = a[0];
    category_rss(id, response, obj, args);
    return;
  }


  obj = model->get_fbobject(args, id);

  if(!obj) 
  {
    response->redirect("/exec/notfound/" + args*"/");
    return;
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
  // attachments and blog entries cannot be blogs.
  if(obj["is_attachment"]!=0)
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
  if(obj["is_attachment"] == 1)
  {
    response->flash("msg", "document requested cannot contain comments.\n");
    response->redirect("/exec/notfound/" +  args*"/");
    return 0;
  }

  array o = obj["comments"];

  Node n = generate_comments_rss(obj, o, id);

  response->set_type("text/xml");
  response->set_data(render_xml(n));
}

private void category_rss(Fins.Request id, Fins.Response response,
  object obj, mixed ... args)
{
  array o = obj["objects"];

  Node n = generate_category_rss(obj, o, id);

  response->set_type("text/xml");
  response->set_data(render_xml(n));
}

private void history_rss(Fins.Request id, Fins.Response response,
  object obj, mixed ... args)
{
  if(obj["is_attachment"] == 1)
  {
    response->flash("msg", "requested object cannot have history.\n");
    response->redirect("/exec/notfound/" + args*"/");
    return;
  }
 
//  array o = obj->get_blog_entries(10);

  Node n = generate_history_rss(obj, find.object_versions((["object": obj])), id);

  response->set_type("text/xml");
  response->set_data(render_xml(n));
}

private Node generate_weblog_rss(object root, array entries, object id)
{
  Node n = new_xml("1.0", "rss");
  n->set_attribute("version", "2.0");
  string x = sprintf( 
                     "href=\"%s\" type=\"text/css\"", 
              (string)Standards.URI("/static/rss.css", 
                    app->get_sys_pref("site.url")["value"]));
  Node ss;
  catch{ ss = n->new_pi("xml-stylesheet", x); };
  if(ss)
    n->add_prev_sibling(ss);
  Node c;

  c = n->new_child("channel", "");
  c->new_child("title", root["title"]);
  c->new_child("link", app->get_sys_pref("site.url")["value"]);
  c->new_child("description", "");
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");

    foreach(entries; int i; object row)
    {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/space/%s", app->get_sys_pref("site.url")["value"], 
        row["path"]));
      item->new_child("guid",  sprintf(
        "%s/space/%s", app->get_sys_pref("site.url")["value"],
        row["path"]))->set_attribute("isPermaLink", "1");
      item->new_child("title", row["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());

      foreach(row["categories"];; object cat)
        item->new_child("category", cat["category"]);

      item->new_child("description", app->render(row["current_version"]["contents"], row, id));
    }
  return n;
}

private Node generate_category_rss(object root, array|object entries, object id)
{
  Node n = new_xml("1.0", "rss");
  n->set_attribute("version", "2.0");

  Node c;

  c = n->new_child("channel", "");
  c->new_child("title", root["category"]);
  c->new_child("link", app->get_sys_pref("site.url")["value"]);
  c->new_child("description", "");
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");

  foreach(FinScribe.Blog.limit(reverse((array)entries), 10);;object row)
  {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/space/%s", app->get_sys_pref("site.url")["value"], 
        row["path"]));
      item->new_child("guid",  sprintf(
        "%s/space/%s", app->get_sys_pref("site.url")["value"],
        row["path"]))->set_attribute("isPermaLink", "1");
      item->new_child("title", row["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());
      item->new_child("description", app->render(row["current_version"]["contents"], row, id));
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
  c->new_child("link", ({ app->get_sys_pref("site.url")["value"], "space",  root["path"] }) * "/" );
  c->new_child("description", app->render(root["current_version"]["contents"], root, id));
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");

  foreach(root["categories"];; object cat)
    c->new_child("category", cat["category"]);

  // we should put the entries in newest first order.
    foreach(FinScribe.Blog.limit(reverse((array)entries), 10); int i; object row)
//    foreach(entries; int i; object row)
    {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/comments/%s#%s", app->get_sys_pref("site.url")["value"], 
        root["path"], (string)row["id"]));

      item->new_child("guid",  sprintf(
        "%s/comments/%s#%s", app->get_sys_pref("site.url")["value"], 
        root["path"], (string)row["id"]))->set_attribute("isPermalink", "1");

      item->new_child("title", row["author"]["username"] + ": " + row["object"]["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());
      item->new_child("description", app->render(row["contents"], row, id));
    }
  return n;
}


private Node generate_history_rss(object root, array entries, object id)
{
  Node n = new_xml("1.0", "rss");
  n->set_attribute("version", "2.0");

  Node c;

  c = n->new_child("channel", "");
  c->new_child("title", root["title"]);
  c->new_child("link", ({ app->get_sys_pref("site.url")["value"], "space",  root["path"] }) * "/" );
  c->new_child("description", "");
// app()->engine->render(root["current_version"]["contents"], (["request": id, "obj": root])));
  c->new_child("generator", version());
  c->new_child("docs", "http://blogs.law.harvard.edu/tech/rss");
  
  foreach(root["categories"];; object cat)
    c->new_child("category", cat["category"]);

  // we should put the entries in newest first order.
    foreach(FinScribe.Blog.limit(reverse((array)entries), 10); int i; object row)
//    foreach(entries; int i; object row)
    {
      Node item = c->new_child("item", "");
      item->new_child("link",  sprintf(
        "%s/space/%s?show_version=%s", app->get_sys_pref("site.url")["value"], 
        root["path"], (string)row["version"]));

      item->new_child("guid",  sprintf(
        "%s/comments/%s#%s", app->get_sys_pref("site.url")["value"], 
        root["path"], (string)row["id"]))->set_attribute("isPermalink", "1");

      item->new_child("title", "Version " + row["version"] + ": " + row["object"]["title"]);
      item->new_child("pubDate", row["created"]->format_smtp());
      item->new_child("description", FinScribe.Blog.make_excerpt(app->render(row["contents"], row, id)));
    }
  return n;
}


#else
public void index(Request id, Response response, mixed ... args)
{
  response->set_data("Public.Parser.XML2 is not installed. RSS feeds are unavailable.");
}
#endif /* Public.Parser.XML2 */
