## User Stories
===============

**Tasks**
* start trying to fix some of the linter errors surrounding exposing(..)
* fix hella busted layout ?
* refactor more of the app module
* rebuild source on save https://maximilianhoffmann.com/posts/how-to-compile-elm-files-on-save
* think about authentication
  -> want to keep it simple
  -> maybe allow users to start simply, and then eventually "create" an account
* upgrade to new way of creating css with elm-css

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io
THEN I should be able to select 'explain difference'

AND when I type in two separate words
THEN I should see it added to my list of french words to explain how they differ

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io
AND I select one of the activities
AND I select 'practice now'
THEN I should be presented with a random item from my list to practice

AND if I click on the 'next' button
THEN I should see the next word in the list

-----

WHEN I do have an internet connection again
AND I tap the "manual sync" button
THEN I should see the unsaved indicator go away
AND if I refresh the page
THEN I should see that none of my phrases are unsaved

------

Icebox
------

* delete items from list
* "practice mode"
* edit the phrase to be translated ?
* shake on validation error (with messages)
* spaced repetition for practice
  - https://www.quora.com/Whats-the-best-spaced-repetition-schedule
  - https://www.supermemo.com/english/ol/nn_train.htm


-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io for the first time
THEN I should be able to see a brief description of how to use the app

AND when I look at the three options (english phrase, french phrase, explain difference)
THEN I should see a proper description of each activity

-----
