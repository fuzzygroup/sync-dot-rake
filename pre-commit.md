hyde
  hyde_site
    .git
      hooks
        pre-commit
    config
      sync_manifest.json
         app/models/url_common.rb
           ../hyde_web           
  hyde_web
    config
      sync_manifest.json
      
      Goal is to prevent you from committing a change to any file identified in any sync_manifest above you
      
      example.  If in hyde_web and change url_common - want an error thrown telling them that they need to change it in the canonical location and here's a handy diff (extra points for that)