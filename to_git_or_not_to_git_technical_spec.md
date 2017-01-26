# To Git Or Not To Git Or To Gem -- Sharing Code Across Multiple Rails Projects

Once you accept that you cannot have a technical world of one single Rails monolith, you have now solved one problem and created another -- how do you share something common across different projects.

## Approach 1: Git SubModule and Git SubTree

Each of these approaches is documented fairly well externally:

* [Winston](http://winstonkotzan.com/blog/2016/09/26/git-submodule-vs-subtree.html)
* [Igor](http://igor-alexandrov.github.io/blog/2013/03/28/using-git-subtree-to-share-code-between-rails-applications/)

My objection to each of these is that they require a pretty decent understanding of git internals / git commands to deal with changes.  Here's an example from the Igor article:

> If you make any commits to the subproject inside master, you can use git subtree split to backport the commits to the right timeline. Let’s split commits that were made to shared folder and push them to foosoftware repository.
> saturn:~/workspace/foolog (dev)$ git subtree split --prefix shared -b backport
> saturn:~/workspace/foolog (dev)$ git push foosoftware backport:dev
> What we’ve done? We splitted all out commits, that changed ‘shared’ folder to a separate branch called backport (use git branch to find it) and then push all these commits to foosoftware/dev branch.

Git SubModule is similar.  Here's an example from Winston:

> Submodules behave like a separate repo within your parent repo. When you are in the submodule directory, you can use Git commands as if you were working on the submodule repo directly. The parent repo only tracks the version of the submodule currently loaded by its commit hash. The parent repo therefore only stays in sync with the shared repo via this reference. Any changes made within the submodule directory cannot be committed by the parent repo. You have to go into the submodule directory and commit/push them from the shared repo.

The other objection that I have with both of these is my fear that because commits have to be done at the submodule / subtree level that they will stack up on an individual's local machine and NOT get pushed when there is a change.  

## Approach 2: Single Git Repo with SymLinks

This is interesting.  I hadn't seen this approach in my last deep dive on the topic.  This approach amounts to creating a single repo with multiple folders at the root level and then you create symlinks for anything shared from the canonical source.  Here's a write up from [Stack Overflow](http://stackoverflow.com/a/11235049/409644).

Pros

* Simple, Clear, Easy
* Better supports things like Github Issues which are at the repo level even tho they often need to span repos

Cons

* Completely breaks the github security model -- security is at the repo NOT chunk of repo level; today this isn't an issue but if we want to be able to farm stuff out granularly, it is a very nice option to have.
* I would really, really want to test this and make damn sure it works
* I would be concerned about editor / tree view issues and would want to be sure that it works
* Windows has issues with symlinks to this day
* How do we merge multiple existing repos into one and not lose our history.

## Approach 3: Make Gems out of Common Code

This is probably the best known approach -- you take a library of code and you make it into a gem so it can be readily re-used across different projects.

Pros: 

* Simple
* Gives something that you could add back to the overall Rails ecosystem if you want to

Cons: 

* Another thing to maintain
* Gems require testing both at the gem level and at the inclusion into the application level (there can be subtle differences depending on the gem and implementation)
* Working on gems is a slightly different mindset than working on a rails app so it requires a brain shift every time you have to work on the gem
* bundle install can be a constant source of failure on deploys; ymmv
* if the code library is changing rapidly then every time you switch projects you may need to re-install.  When working on something with say 5 or 6 discrete pieces, its not inconceivable that you might do bundle install that may times

## Approach 4: One Canonical Source and a Copy Mechanism

Of all these approaches, the one I personally like best amounts to this:

* Designate a canonical source for a shared file
* Change that file only in that canonical place
* Add to the master source a rake task which copies that file to all its possible destinations
* Modify every engineer's git hooks file so that changes to those canonical files are not allowed

I stole this fairly shamelessly from [Hiltmon](http://hiltmon.com/blog/2013/10/14/rails-tricks-sharing-the-model/) and I've employed this on about three different ocassions and I have had good luck with it.  The reason that I like it is that it is brilliant in its simplicity and it is easy to understand.  I've never once felt good about git sub module / git sub tree -- it always feels like something is going to bite me.  

In order to really make this work a .githooks/pre-commit file needs to exist on each engineer's workstation that essentially took the array of changed files and then compared it against a source list and excluded each file that was on the source list.  