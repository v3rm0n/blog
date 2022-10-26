---
layout: post
title:  "Reddit 'On vote move down' userscript"
tags: reddit javascript software
---

I recently switched from Linux back to Mac. I have actually been a Mac user for many years, but I
didn't like where they were going with the Touch Bar and always chasing to reduce the thickness,
often causing
issues with usability like with the butterfly keyboard. When I saw that the new MacBook was actually
thicker(!) than the previous one, and they removed the Touch Bar I decided to give it another
chance.

After switching back I decided to switch from Firefox to Safari as well to maximise battery.
Unfortunately the [Reddit Enhancement Suite][res] does not work on Safari.

When I started thinking about what I actually needed it for, I managed to reduce it to three things:

- Voting and moving to the next entry using the keyboard (A to vote up, Z for down)
- Expanding the content of the active post (using X) and keep it expanded if I move to the next post
  by voting
- Dark mode

Fortunately, like most browsers, Safari supports something called [user scripts][userscripts-wiki]
using an [extension][userscripts]. Which basically means that I can write some JavaScript to modify
a webpage however I like.

Userscripts consist of some metadata in the header comment which specifies the name, description and
the rules for execution of the script.

So the script I came up with is the following:

```javascript
// ==UserScript==
// @name        OnVoteMoveDownReddit
// @description Simple script that allows using a/z for voting and on vote will move to next element and expand it in Reddit. x will expand the thing if it is not already expanded. When at the end of the page, new content is loaded automatically
// @exclude     https://old.reddit.com/r/*/comments/*
// @exclude     https://www.reddit.com/r/*/comments/*
// @match       https://old.reddit.com/r/*
// @match       https://old.reddit.com/
// @match       https://www.reddit.com/r/*
// @match       https://www.reddit.com/
// ==/UserScript==

// CSS for the active thing
const style = document.createElement("style");
style.type = "text/css";
style.innerHTML =
    ".thing.active { border-style: dotted; border-color: cornflowerblue; }";
document.getElementsByTagName("head")[0].appendChild(style);

// Things are content
const things = document.getElementsByClassName("thing");

const makeActive = (element) => element.classList.add("active");

const makeInactive = (element) => element.classList.remove("active");

const clearPreviousActive = () => {
  for (let thing of things) {
    makeInactive(thing);
  }
};

// Event listeners for activating a thing by clicking on it
for (let thing of things) {
  thing.addEventListener("click", (event) => {
    clearPreviousActive();
    makeActive(event.currentTarget);
  });
}

// Activate first thing by default
makeActive(things[0]);

// Loads next page of 100 things and parses out the list of them
const loadNext = async (lastThing) => {
  const id = lastThing.getAttribute("data-fullname");
  const response = await fetch(
      `${window.location.href.split("?")[0]}?count=100&after=${id}`
  );
  const allContent = await response.text();
  const parser = new DOMParser();
  const htmlDocument = parser.parseFromString(allContent, "text/html");
  const siteTable = htmlDocument.documentElement.querySelector("#siteTable");
  return siteTable.children;
};

// Removes nav buttons and appends new things to the content. New content has its own nav buttons.
const addContentToPage = (lastThing, content) => {
  document.querySelector(".nav-buttons").remove();
  for (let thing of content) {
    lastThing.parentElement.append(thing);
  }
};

const getLastThing = () => {
  const allThings = document.querySelectorAll(".thing");
  return allThings[allThings.length - 1];
};

const loadMoreContent = async () => {
  const lastThing = getLastThing();
  const content = await loadNext(lastThing);
  addContentToPage(lastThing, content);
};

const expand = (thing) => {
  const expandButton = thing.querySelector("div.expando-button.collapsed");
  if (expandButton) {
    expandButton.click();
  }
};

const collapse = (thing) => {
  const collapseButton = thing.querySelector("div.expando-button.expanded");
  if (collapseButton) {
    collapseButton.click();
  }
};

const getNextSibling = (elem, selector) => {
  // Get the next sibling element
  let sibling = elem.nextElementSibling;

  // If the sibling matches our selector, use it
  // If not, jump to the next sibling and continue the loop
  while (sibling) {
    if (sibling.matches(selector)) return sibling;
    sibling = sibling.nextElementSibling;
  }
};

let autoExpand = false;

const moveToNext = (current) => {
  collapse(current);
  // Get next thing that is not an ad
  const nextThing = getNextSibling(current, ".thing:not(.promoted)");
  clearPreviousActive();
  makeActive(nextThing);
  if (autoExpand) {
    expand(nextThing);
  }
  nextThing.scrollIntoView(true);
  if (window.innerHeight + window.scrollY >= document.body.offsetHeight) {
    // you're at the bottom of the page
    loadMoreContent();
  }
};

document.addEventListener(
    "keydown",
    (event) => {
      const keyName = event.key;
      const currentActive = document.querySelector(".thing.active");
      if (currentActive) {
        switch (keyName) {
          case "a":
            const upArrow = currentActive.querySelector(".arrow.up");
            upArrow.click();
            moveToNext(currentActive);
            break;
          case "z":
            const downArrow = currentActive.querySelector(".arrow.down");
            downArrow.click();
            moveToNext(currentActive);
            break;
          case "x":
            autoExpand = !autoExpand;
            if (autoExpand) {
              expand(currentActive);
            } else {
              collapse(currentActive);
            }
            break;
        }
      }
    },
    false
);
```

I haven't managed to fix the Dark Mode issue yet because I did not find any good color combinations
for the font and the background that work well.

[res]: https://redditenhancementsuite.com

[userscripts-wiki]: https://en.wikipedia.org/wiki/Userscript

[userscripts]: https://apps.apple.com/us/app/userscripts/id1463298887