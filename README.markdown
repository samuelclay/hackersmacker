# Hacker Smacker
### Friend/foe individual writers on Hacker News.

## Synopsis

Hacker Smacker helps you identify quality authors and filter out obnoxious commenters on Hacker News. Three little orbs appear next to every author's name and you can choose to either friend or foe them.

What's neat is that if you friend people, and they also use Hacker Smacker, you'll see all of your friend's friends and foes. This helps you identify commenters that you want to read as you quickly scan a comment thread. I've found that this reduces the time I spent on Hacker News, as I can glance at long comment threads and just find the good stuff.

Hacker Smacker is directly inspired by Slashdot's friend/foe system.

## Installation

Hacker Smacker is divided into two parts:

 * **Client**: the extension that gets injected into Hacker News and reports back 
               with friends and foes.
 * **Server**: the Node.js/Express.js/Redis system that keeps track of all friends/foes 
               and friend of a friend and foe of a friend relationships.

### <img src="https://www.hackersmacker.org/images/safari.png" width="32"> Safari client

[Download the Safari extension](https://github.com/samuelclay/hackersmacker/blob/master/client/Safari.safariextz?raw=true)

To install just double-click the downloaded extension.

### <img src="https://www.hackersmacker.org/images/chrome.png" width="32"> Chrome client

[Download the Chrome extension](https://github.com/samuelclay/hackersmacker/blob/master/client/chrome.crx?raw=true)

To install the Chrome extension, you cannot double-click it (unfortunately, Chrome no longer allows this). Instead, drag it into Chrome's Extensions page at <a href="chrome://extensions">chrome://extensions</a>.

### <img src="https://www.hackersmacker.org/images/firefox.png" width="32"> Firefox client

[Download the Firefox extension](https://github.com/samuelclay/hackersmacker/blob/master/client/firefox.xpi?raw=true)

To install the Firefox extension, just drag the .xpi file into an open Firefox window.

### Server

You don't need to install the server unless you want to run your own private version of Hacker Smacker. If you do decide to install your own server, you're on your own.
 
## Screenshots

A friend or foe has not yet been made. The standard orb:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/master/docs/screenshot1.png)

Choosing a friend or foe. Animation provides a nice slide out:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/master/docs/screenshot2.png)

A blend of friends and foes illustrating the transformative experience of Hacker Smacker:

![](https://raw.githubusercontent.com/samuelclay/hackersmacker/master/docs/screenshot3.png)

## Examples of great Hacker News comments from which to start a collection of friends

 * [http://news.ycombinator.com/item?id=3871674](http://news.ycombinator.com/item?id=3871674)
 * [http://news.ycombinator.com/item?id=3543440](http://news.ycombinator.com/item?id=3543440)
 * [http://news.ycombinator.com/item?id=3576217](http://news.ycombinator.com/item?id=3576217)
 * [http://news.ycombinator.com/item?id=3679698](http://news.ycombinator.com/item?id=3679698)
 * [http://news.ycombinator.com/item?id=3702513](http://news.ycombinator.com/item?id=3702513)
 * [https://news.ycombinator.com/item?id=7755927](https://news.ycombinator.com/item?id=7755927)
 * [https://news.ycombinator.com/item?id=8082029](https://news.ycombinator.com/item?id=8082029)

## Acknowledgements

 * **Mihai Parparita** <mihaip@chromium.org> - Help with fixing the issue around browsers not allowing a JSONP AJAX request to modify the page, as it is sandboxed and cannot alter the page using arbitrary JavaScript (the JSONP) not included with the extension itself.
 
## License

 * MIT License

## Background

Hacker Smacker was built to learn how FoaF (Friend of a Friend) works. The idea is that not only do you want to surface content from your friends, but if you chose your friends well, they can help you surface more great content by highlighting comments from their friends.

The impetus for building a small system where the primary goal is simply to quickly show relationships was that I wanted to build the same system for [NewsBlur](http://www.newsblur.com), a visual RSS feed reader with intelligence. The backend is built using [Redis](http://redis.io) sets and CoffeeScript/Node.js. NewsBlur's social layer, which was built immediately after this project, uses a very similar backend. 

Learning how to build this project was the main reason, as I am now able to bring this technique to other projects.

## Author

 * **Samuel Clay**: [samuel@ofbrooklyn.com](mailto:samuel@ofbrooklyn.com)
 * **On the web**: [www.samuelclay.com](http://www.samuelclay.com)
 * **Twitter**: [@samuelclay](http://twitter.com/samuelclay)
 