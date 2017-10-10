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
