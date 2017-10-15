## User Stories
===============

GIVEN that I am a non-native french speaker
WHEN I do not have an internet connection
AND I am practicing french phrases
AND I enter a phrase
THEN I should see an indication that it has not been saved

WHEN I do have an internet connection again
AND I tap the "manual sync" button
THEN I should see the unsaved indicator go away
AND if I refresh the page
THEN I should see all of my phrases

-----

Given that I am a non-native french speaker
When I enter some french phrases to practice
Then I should be able to add translations as well

-----

Icebox
------

* delete items from list
* css (bootstrap, with elm-css ???)
* "practice mode"
* two-sided cards ?
* remove dupes
* shake on validation error
* show user when they are offline
* manual re-sync when there are changes to sync

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io
THEN I should be able to select 'english phrase'

AND when I type in a english phrase
THEN I should see it added to my list of english phrases to translate later

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io
THEN I should be able to select 'explain difference'

AND when I type in two separate words
THEN I should see it added to my list of french words to explain how they differ

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io for the first time
THEN I should be able to see a brief description of how to use the app

AND when I look at the three options (english phrase, french phrase, explain difference)
THEN I should see a proper description of each activity

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io
AND I select one of the activities
AND I select 'practice now'
THEN I should be presented with a random item from my list to practice

AND if I click on the 'next' button
THEN I should see the next word in the list
