//<locale-token project="FinScribe">LOCALE</locale-token>

#define LOCALE(X,Y) Locale.translate(config->app_name, id->get_lang(), X, Y)

import Fins;
import Fins.Model;
inherit Fins.FinsModel;
import Tools.Logging;

int lower_case_link_names = 1;

//! @deprecated
DataModelContext context;

//object datatype_instance_module = FinScribe.Objects;
//object datatype_definition_module = FinScribe.DataMappings;

//object repository = FinScribe.Repo;

// because we might be starting the app in "install mode", we 
// override the default loader to check for that scenario.
public void load_model()
{
  if(!config["application"] || !config["application"]["installed"]) 
  {
    Log.info("Not starting model.");
    return 0;
  }
  else
  {
    Log.info("Starting model.");
  }

  ::load_model();

  // context is used by some legacy code, so we'll manually populate it (for now);
  context = Fins.Model.get_default_context();
}

//! given a path p, find the path component closest to p that represents
//! an actual object. if none exists, return 0.
Model.DataObjectInstance find_nearest_parent(string path)
{
  array a = path/"/";

  for(int i = sizeof(a); i != 0; i--)
  {
    string p = (a[0..(i-1)] * "/");
    mixed o = context->find->objects((["path": p]));
    if(sizeof(o)) return o[0];
  }

  return 0;
}

// return the last component of a path.
// for example, get_object_name("/path/to/document") would return "document".
string get_object_name(string n)
{
  return (n/"/")[-1];
}

//! a cache-enabled version of find.datatypes_all().
mixed get_datatypes()
	{
  mixed res;

  res = cache->get("DATATYPES_");
  
  if(res) return res;

  res = context->find->datatypes_all();

  cache->set("DATATYPES_", res, 600);

  return res;
}

//! decode the metadata field in object obj.
mixed get_metadata(object obj)
{
  string md = obj["metadata"];
  if(md && strlen(md))  
    return decode_value(md);
  else return ([]);
}

//! encode the data metadata into the metadata field in object obj.
void set_metadata(object obj, mixed metadata)
{  obj["metadata"] = encode_value(metadata);
}

//! a cache-enabled version of find.categories_all().
mixed get_categories()
{
  mixed res;

  res = cache->get("CATEGORIES_");
  
  if(res) return res;

  res = context->find->categories_all();

  cache->set("CATEGORIES_", res, 600);

  return res;
}

//! clear the category cache
void clear_categories()
{
  cache->clear("CATEGORIES_");
}

//! a cache enabled version of find.objects_by_alt()
public object get_fbobject(array|string args, Request|void id)
{
   object r;
   string a = (stringp(args)?args:(args*"/"));

   r=cache->get("PATHOBJECTCACHE_" + a);

   if(r) return r;

   mixed e = catch(r = context->find->objects_by_path(a));

   // TODO: we should do something with the error rather than just swallow it.

   if(r)
   {
     cache->set("PATHOBJECTCACHE_" + a, r, 600);
     return r;
   }
   else return 0;
}

function get_when = Tools.String.friendly_date;

//! convenience function used by installer.
int new_from_string(string path, string contents, string type, int|void att, int|void skip_if_exists)
{
  int isnew = 1;
  object obj_o;
  array dtos = context->find->datatypes((["mimetype": type]));
               if(!sizeof(dtos))
               {
                  throw(Error.Generic("Mime type " + type + " not valid."));
               }
               else{
               object dto = dtos[0];
  mixed a;
  catch(a = context->find->objects((["path": path]) ));
  if(a && sizeof(a))
  {
    if(skip_if_exists) return 0;
    obj_o  = a[0];
    isnew=0;
  }
  else
               obj_o = FinScribe.Objects.Object();
               obj_o["datatype"] = dto;
               if(att)
                 obj_o["is_attachment"] = 1;
               else 
                 obj_o["is_attachment"] = 0;
               obj_o["author"] = context->find->users_by_id(1);
               obj_o["datatype"] = dto;
               obj_o["path"] = path;
           if(isnew)
            obj_o->save();

            object obj_n = FinScribe.Objects.Object_version();
            obj_n["contents"] = contents;

            int v;
            object cv;

            obj_o->refresh();

            if(cv = obj_o["current_version"])
            {
              v = cv["version"];
            }
            obj_n["version"] = (v+1);
            obj_n["object"] = obj_o;
            obj_n["author"] = context->find->users_by_id(1);
            obj_n->save();
            return 1;

            }
}

private void do_trackback_ping(array trackbacks, object obj_o, object u)
{
  foreach(trackbacks;; string url)
    Thread.Thread(FinScribe.Blog.trackback_ping, obj_o, u, url);
 
}


int delete_post(object id, object obj_o, object user, int publish)
{
   if(!obj_o->is_deleteable(user)) 
   {
     throw(Error.Generic(LOCALE(406,"You don't have permission to delete this object.")));
   }

    cache->clear(sprintf("CACHEFIELD%s-%d", "current_version", obj_o->get_id()));
    cache->clear(app->get_renderer_for_type(obj_o["parent"]["datatype"]["mimetype"])->make_key(obj_o["parent"]->get_object_contents(),
      obj_o["parent"]["path"]));

    app->trigger_event("postDelete", id, obj_o["path"]);
    obj_o->delete(1);
}

object add_media(object id, object parent, object user, string name, string type, string contents, 
  mapping|void struct)
{
  object obj_o; // the new object, oddly named.
   if(!parent->is_writeable(user))
   {
     throw(Error.Generic(LOCALE(406,"You don't have permission to write to this object (" + parent["path"] + ").")));
   }

   array dtos = context->find->datatypes((["mimetype": type]));
   if (!sizeof(dtos))
   {
     throw (Error.Generic(LOCALE(402, "Content type " + type + " not configured, unable to save.")));
     return 0;
   }
   string path = combine_path(parent["path"], name);
   obj_o = get_fbobject(path);

   object dto = dtos[0];

   if(!obj_o) // new object
   {
     obj_o = context->new("Object");
     obj_o["is_attachment"] = 1;
     obj_o["parent"] = parent;
     obj_o["path"] = path;
     obj_o["author"] = user;
     obj_o["datatype"] = dto;
     obj_o->save();
   }
   else
   {
     obj_o["datatype"] = dto;
     obj_o["author"] = user;
   }
   object obj_n = context->new("Object_version");
   obj_n["contents"] = contents;
   int v;
   object cv;

   obj_o->refresh();

   if(cv = obj_o["current_version"])
   {
     v = cv["version"];
   }
   obj_n["version"] = (v+1);
   obj_n["object"] = obj_o;
   obj_n["author"] = user;
   obj_n->save();
   cache->clear(sprintf("CACHEFIELD%s-%d", "current_version", obj_o->get_id()));
   
   return obj_o;  
}

object do_post(object id, object obj_o, object user, string subject, string contents, string createddate, array|void categories, int publish, int|void is_update)
 {
    object c, p;
    object obj_n;
    string obj = obj_o["path"];
    string trackbacks = "";

   if(!obj_o->is_postable(user)) 
   {
     throw(Error.Generic(LOCALE(406,"You don't have permission to publish (post) this object.")));
   }

    if (createddate && sizeof(createddate))
      c = Calendar.Gregorian.dwim_day(createddate)->second();
    else
      c = Calendar.ISO.Second();
    string date = sprintf("%04d-%02d-%02d", c->year_no(), c->month_no(), c->month_day());

    // posting should always create a new entry; afterwards it's a standard object
    // that you can edit normally by editing its object content.
    if(is_update)
    {
        p = obj_o;
    }
    else
    {
        array dtos = context->find->datatypes((["mimetype": "text/wiki"]));
        if (!sizeof(dtos))
        {
            throw (Error.Generic(LOCALE(402, "Internal Database Error, unable to save.")));
            return 0;
        }

        // let's get the next blog path name...
        string path = "";
        array r = obj_o->get_blog_entries(0,0,1);
        int seq = 1;
        if (sizeof(r))
        {
            foreach(r;; object entry)
            {
                //                 write("LOOKING AT " + entry["path"] + "; does it match " + obj + "/" + date + "/ ?\n");
                // we assume that everything in here will be organized chronologically, and that no out of
                // date order pathnames will show up in the list.
                if (has_prefix(entry["path"], obj + "/" + date + "/"))
                seq++;
                else break;
            }
        }

        path = combine_path(obj, date + "/" + seq);

        // this is the parent, to which the new entry is associated.
        p = obj_o;
werror("creating new object\n");
        object dto = dtos[0];
        obj_o = context->new("Object");
        obj_o["datatype"] = dto;
        obj_o["datatype"] = dto;
        obj_o["path"] = path;
        obj_o["parent"] = p;

        }

        obj_o["author"] = user;

        if (!publish)
        {
            object s_acl = context->find->acls_by_name("Work In Progress Object");
            if (!s_acl) s_acl = p["acl"];

            obj_o["acl"] = s_acl;
        }
        else
          obj_o["acl"] = p["acl"];

        obj_o["created"] = c;

        if (!publish)
          obj_o["is_attachment"] = 3;
        else
          obj_o["is_attachment"] = 2;

        if(!is_update)
          obj_o->save();

werror("creating new version\n");

    obj_n = context->new("Object_version");
    obj_n["contents"] = contents;
    obj_n["subject"] = subject;
    obj_n["created"] = c;
    int v;
    object cv;

    obj_o->refresh();

    if (cv = obj_o["current_version"])
    {
        v = cv["version"];
    }
    obj_n["version"] = (v + 1);
    obj_n["object"] = obj_o;
    if (subject)
    obj_n["subject"] = subject;
    obj_n["author"] = user;
    obj_n->save();

    if(categories && sizeof(categories))
    {
       mixed cats = context->find->categories((["category": categories]));
       if(is_update)
         cats -= (array)obj_o["categories"];
       foreach(cats;; mixed c)
         obj_o["categories"] += c;
    }

    cache->clear(sprintf("CACHEFIELD%s-%d", "current_version", obj_o->get_id()));

    if (publish)
    {
        // we use this object for both trackback and pingback processing.
        object u = Standards.URI(app->get_sys_pref("site.url")->get_value());
        u->path = combine_path(u->path, "/space");

        app->render(contents, obj_o, id);
        array bu = (replace(trackbacks, "\r", "") / "\n" - ({
            ""
        }));
        if (id->misc->permalinks)
        {
            foreach(id->misc->permalinks, string url)
            {
                string l;
                l = FinScribe.Blog.detect_trackback_url(url);
                if (l && search(bu, l) == -1)
                bu += ({
                    l
                });
            }
        }
        trackbacks = Array.uniq(bu) * "\n";

        if (sizeof(trackbacks))
        {
            Thread.Thread(do_trackback_ping, (trackbacks / "\n") - ({
                ""
            }), obj_o, u);
        }
    }
    cache->clear(app->get_renderer_for_type(obj_o["parent"]["datatype"]["mimetype"])->make_key(obj_o["parent"]->get_object_contents(),
    obj_o["parent"]["path"]));

    app->trigger_event("postSave", id, obj_o);
    return obj_o;
}


