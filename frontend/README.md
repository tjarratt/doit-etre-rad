## User Stories
===============

---------------------------
**Icebox and sundry Tasks**
---------------------------
* fix hella busted layout ?
  - shh button slightly off-center
  - word cards (placement ?)
  - word translations (length ?)
* rebuild source on save https://maximilianhoffmann.com/posts/how-to-compile-elm-files-on-save
* think about authentication
  -> want to keep it simple
  -> maybe allow users to start simply, and then eventually "create" an account
* upgrade to new way of creating css with elm-css
* fix even more lint errors ?
* after saving from backend, local storage is out of date
  -> most recent phrase is still "unsaved" :-\
* focus input when page is shown
  -> ("pageshow" event, see "safariwebcontent" docs on handling events)
* delete items from list
* reverse sort phrases so I see newest ones at top
* edit the phrase to be translated ?
* shake on validation error (with messages)
* spaced repetition for practice
  - https://www.quora.com/Whats-the-best-spaced-repetition-schedule
  - https://www.supermemo.com/english/ol/nn_train.htm
* manual sync ?
* http://www.eq8.eu/blogs/44-csrf-protection-on-single-page-app-api

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

-----

GIVEN that I am a non-native french speaker
WHEN I on the homepage of doit-etre-rad.cfapps.io for the first time
THEN I should be able to see a brief description of how to use the app

AND when I look at the three options (english phrase, french phrase, explain difference)
THEN I should see a proper description of each activity

-----
