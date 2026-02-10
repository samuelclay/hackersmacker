<p align="center">
  <img src="web/images/hackersmacker_logo.png" alt="Hacker Smacker" width="420">
</p>

<h4 align="center"><em>Friend/foe individual writers on Hacker News</em></h4>

<p align="center">
  <img src="docs/pill-friend.svg" height="14"> Friend&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/pill-neutral.svg" height="14"> Neutral&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/pill-foe.svg" height="14"> Foe
</p>
<p align="center">
  <img src="docs/pill-foaf-friend.svg" height="14"> Friend of a Friend&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="docs/pill-foaf-foe.svg" height="14"> Foe of a Friend
</p>

---

## Synopsis

Hacker Smacker helps you identify quality authors and filter out obnoxious commenters on Hacker News. Three little orbs appear next to every author's name and you can choose to either friend or foe them.

> If you friend people, and they also use Hacker Smacker, you'll see all of your friend's friends and foes. This helps you identify commenters that you want to read as you quickly scan a comment thread.

I've found that this reduces the time I spent on Hacker News, as I can glance at long comment threads and just find the good stuff.

Hacker Smacker is directly inspired by Slashdot's friend/foe system.

## Screenshots

A friend or foe has not yet been made. The standard orb:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/main/docs/screenshot1.png)

Choosing a friend or foe. Animation provides a nice slide out:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/main/docs/screenshot2.png)

A blend of friends and foes illustrating the transformative experience of Hacker Smacker:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/main/docs/screenshot3.png)

## Get the Extension

### <img src="web/images/chrome.png" width="32"> Chrome

**From the Web Store:** [Install from Chrome Web Store](https://chrome.google.com/webstore/detail/hacker-smacker/) <!-- Update with actual Web Store URL -->

**Load unpacked (development):**
1. Go to `chrome://extensions`
2. Enable "Developer mode" (top right)
3. Click "Load unpacked" and select the `client/chrome/` directory

### <img src="web/images/firefox.png" width="32"> Firefox

**From Add-ons:** [Install from Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/hacker-smacker/)

**Load temporarily (development):**
1. Go to `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on"
3. Select `client/firefox/manifest.json`

### <img src="web/images/safari.png" width="32"> Safari

**From the App Store:** [Install from Mac App Store](https://apps.apple.com/app/hacker-smacker/) <!-- Update with actual App Store URL -->

**Build from source (development):**
1. Open `client/safari/Hacker Smacker/Hacker Smacker.xcodeproj` in Xcode
2. Build and run (Cmd+R)
3. Enable the extension in Safari > Settings > Extensions

## Great comments to start your collection

 * [news.ycombinator.com/item?id=3871674](http://news.ycombinator.com/item?id=3871674)
 * [news.ycombinator.com/item?id=3543440](http://news.ycombinator.com/item?id=3543440)
 * [news.ycombinator.com/item?id=3576217](http://news.ycombinator.com/item?id=3576217)
 * [news.ycombinator.com/item?id=3679698](http://news.ycombinator.com/item?id=3679698)
 * [news.ycombinator.com/item?id=3702513](http://news.ycombinator.com/item?id=3702513)
 * [news.ycombinator.com/item?id=7755927](https://news.ycombinator.com/item?id=7755927)
 * [news.ycombinator.com/item?id=8082029](https://news.ycombinator.com/item?id=8082029)
 * [news.ycombinator.com/item?id=19775789](https://news.ycombinator.com/item?id=19775789)

## Background

Hacker Smacker was built to learn how FoaF (Friend of a Friend) works. The idea is that not only do you want to surface content from your friends, but if you chose your friends well, they can help you surface more great content by highlighting comments from their friends.

The impetus for building a small system where the primary goal is simply to quickly show relationships was that I wanted to build the same system for [NewsBlur](http://www.newsblur.com), a visual RSS feed reader with intelligence. The backend is built using [Redis](http://redis.io) sets and CoffeeScript/Node.js. NewsBlur's social layer, which was built immediately after this project, uses a very similar backend.

Learning how to build this project was the main reason, as I am now able to bring this technique to other projects.

## Installation

Hacker Smacker is divided into two parts:

 * **Client**: the extension that gets injected into Hacker News and reports back with friends and foes.
 * **Server**: the Node.js/Express.js/Redis system that keeps track of all friends/foes and friend of a friend and foe of a friend relationships.

You don't need to install the server unless you want to run your own private version of Hacker Smacker. If you do decide to install your own server, you're on your own.

## Acknowledgements

 * **Mihai Parparita** [mihaip@chromium.org](mailto:mihaip@chromium.org) — Help with fixing the issue around browsers not allowing a JSONP AJAX request to modify the page, as it is sandboxed and cannot alter the page using arbitrary JavaScript (the JSONP) not included with the extension itself.

 * **Greg Brockman** [greg@gregbrockman.com](mailto:greg@gregbrockman.com) — Helped design the authentication system, working through the security model to ensure that friend/foe relationships could be stored and verified without exposing user credentials.

## Privacy Policy

None of the data stored by Hacker Smacker is sold or used in any way except for determining friend/foe and friend/foe of a friend relationships between authors.

## Why the chair?

Some people express their enthusiasm for colleagues by friending them. Others, famously, express it by hurling furniture across the room. The chair is a nod to one such enthusiast who shall remain nameless, but who once demonstrated that the pen is mightier than the sword, and the chair is mightier than both. Besides, a launched laptop makes everyone reconsider.

## License

MIT License

## Author

 * **Samuel Clay**: [samuel@ofbrooklyn.com](mailto:samuel@ofbrooklyn.com)
 * **On the web**: [samuelclay.com](http://www.samuelclay.com)
 * **X**: [@samuelclay](https://x.com/samuelclay)
