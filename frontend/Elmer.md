Things I believe about Elmer

* you can be forced to stub commands from within the same module
  (e.g. your app module)
  but you can't see that they were invoked
* same as above, but with ports ?
* type-arity of spies is REALLY important, but has bad error messages
  - too many ? it silently doesn't call your spy
  - too few ? it blows up during test execution
* elmer http
  - seems you can't add two spies with the same URL, differing verbs
* elmer html
  - jesus christ
  - apparently if you have a selector like
        '#container tag#something'
    or even
        '#container tag:pseudo-selector'
    it actually selects the first 'tag' in '#container'
* spies
  -> turns out that you can't add a spy for a second module right now
     Assume you're testing App, which in turns uses a Component module.
     Component.update creates a Task, which elmer needs to be stubbed.
     Unfortunately, the spies you register are not seen at runtime by elmer.
