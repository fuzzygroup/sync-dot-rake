# sync-dot-rake
A rake task to be added to your Rails projects for synching files across multiple Rails apps.

This open source project is either something that you will get right away or you will think I'm a raving loon and this is entirely unnecessary.  And, I suspect, that depending on your perspective, either could be true.  

And, yes, I really think this should come from the version control tool.  Sadly I haven't found git's implementation of this to be worthy so far.  But given that that's my only complaint about git in over a decade of daily usage, I really can't complain.  Go Linus!

## Overview

In the summer of 2016 I started building Rails apps that weren't the traditional rails monoltih.  I've been dissatisfied with the Rails monolith pattern for some time and this was the first case where I had a (paid) opportunity to experiment.  What I did was write a traditional Rails crud app with an external api based on the  Rails API option (--api)  as a separate git project.  What I found was that I needed to share common code libraries, for text processing, between the two projects.  Since this was green field development, routines were changing constantly.  The traditional option of sharing code across Rails projects -- gem creation -- simply wasn't an option.  There was no way that I was going to introduce a third bit of code that I had to maintain and then constantly be screwing around with bundle install.  Not.  Going.  To.  Happen.

And then I found hiltmon and it all became clear to me:

> I am building a series of Rails applications for different users and use cases, but they all hang off the same database schema. Using canonical Rails, that means a single, massive rails app with a bunch of controllers, a heap of views and a complex security model. [Hiltmon](http://hiltmon.com/blog/2013/10/14/rails-tricks-sharing-the-model/)

And I used his approach for that project and all was happiness and snuggle bunnies. Seriously.

## Then Came A Client

So after using his approach, I started doing some work in December 2016 for a client where they wanted a user creation API that worked alongside their two existing rails apps.  I dusted off my research skills and produced a white paper describing the options and this option and I convinced them to go this route using the sales pitch "This is the least shitty solution of a series of shitty solutions".  Seriously.  Here's the [white paper](to_git_or_not_to_git_technical_spec.md) I wrote with the client specific info removed.  Thanks to Sam, Josh, Robbie and Michael for all their feedback.  A particular shout out to Josh who picked the most holes in this and directly led to the most sweeping changes.

## How this All Works

After getting feedback from the client, I invented a side project (a SAAS app) with the following sub apps to prove out this in a large context:

* admin -- the admin tools to run the app
* site -- the public facing web site for signup and payment processing / account creation
* web -- the actual SAAS app 
* worker -- the background processing tasks
* api_ruby -- the api; no activerecord support at all for honesty's sake

Each of these is either a full stack Rails app or a Rails api app.  Their directory structure, consequently, is absolutely common.  What I found is that there are a lot of commonalities: 

* admin needs to access the logins table for viewing and reporting
* admin needs to access the payment tables for tracking $$$ flow
* web needs access to the user data and account data
* web needs access to the core tools like url_common.rb, text_common.rb 
* worker needs the user created data (posts, etc)
* api_ruby needs access to the core tools like url_common.rb, text_common.rb 
* web needs access to the site footer

What I found is that each of these sub apps owns some level of functionality that it needs to share with 1 or more other sub apps

My original approach to sync.rake had  the files to copy defined directly in the rake task itself.  This works fine when you are in a **broadcast** model where there is 1 master and N destinations.  But this approach is clearly a **multicast**  where there are N masters and N destinations.

The solution I came up with was a json manifest which expresses where things go when the rake task runs.  Here's an actual example as it has evolved over the past week:

    {
      "comment_1": "This file is a json manifest of files to sync to other rails git repos",
      "comment_2": "Assumptions - all git checkouts for the organizations are in a single",
      "comment_3": "directory and only relative pathing is used assuming Rails.root at the",
      "comment_4": "base",
      "comment_5": "All comment_ json elements will be discarded",
      "comment_6": "execute manifest with bundle exec rake sync:copy_manifest",

  
      "files":{
        "lib/tasks/sync.rake":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/db.rb":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/login.rb":[
            "../hyde_web"],
        "db/migrate/20170123070515_create_logins.rb": [
          "../hyde_web"],
          "app/models/url_common.rb":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/text_common.rb":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/time_common.rb":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/blog_analyzer.rb":[
          "../hyde_web",
          "../hyde_api_ruby",
          "../hyde_admin",
          "../hyde_worker"],
        "app/models/user.rb":[
          "../hyde_web",
          "../hyde_worker"],      
        "app/views/shared/_spacer.html.erb":[
          "../hyde_web"],
        "app/views/layouts/_footer.html.erb":[
          "../hyde_web",
          "../hyde_admin"]   
        }
    }
    
Yes the base project name is hyde; make of that what you will.

## Core Assumptions

Here are the core assumptions governing all of this:

* all sub apps are hosted in a single directory with subdirectories for each of them
* pathing has to be relative for this to work

## Putting All The Pieces Together

Here are the different pieces and where they go:

1.  lib/tasks/sync.rake
2.  config/sync_manifest.json
3. .git/hooks/pre-commit

The rake task reads from the manifest and moves files around as needed.

The manifest declares where stuff goes.

The final piece, a git pre-commit hook, prevents you from making changes to a file that you shouldn't.  That piece is still being finished now.

## How to Begin

1.  Create a sync.rake file in lib/tasks/ of any of your rails projects where you want to sync files from location X to location Y, Z or A', etc
2.  Write a sync_manifest.json file in config/
3. Run **bundle exec rake sync:copy --trace**
4. Wait for me to finish the pre-commit hook (this is really important so you might just want to wait for now).