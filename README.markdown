# Hacker Smacker
### Friend/foe individual writers on Hacker News.

## Synopsis

If you've read Slashdot you know all about the friend/foe system. Next to each 
author is an orb that shows your relationship to the author -- if you've friended 
or foe'd them. This helps you identify quality authors and filter out obnoxious commenters.

## Installation

Hacker Smacker is divided into two parts:

 * **Client**: the extension that gets injected into Hacker News and reports back 
               with friends and foes.
 * **Server**: the Node.js/Express.js/Redis system that keeps track of all friends/foes 
               and friend of a friend and foe of a friend relationships.

### Safari client

[Download the Safari extension](https://github.com/samuelclay/HACKERSMACKER/blob/master/client/safari/Safari.safariextz?raw=true)

### Chrome client

### Firefox client

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
 