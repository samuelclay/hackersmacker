# HACKERSMACKER
### Friend/foe individual writers on Hacker News.

## Synopsis

If you've read Slashdot you know all about the friend/foe system. Next to each author is an orb that shows your relationship to the author -- if you've friended or foe'd them. This helps you identify quality authors and filter out obnoxious commenters.

This system provides two parts:
 * **Client**: the extension that gets injected into Hacker News and reports back with usernames to compare) and the server.
 * **Server**: the Node.js/Express.js/Redis system that keeps track of all friends/foes and friend of a friend and foe of a friend relationships.
 
## Screenshots

A friend or foe has not yet been made. The standard orb:

![](http://github.com/samuelclay/HACKERSMACKER/raw/master/docs/screenshot1.png)

Choosing a friend or foe. Animation provides a nice slide out:

![](http://github.com/samuelclay/HACKERSMACKER/raw/master/docs/screenshot2.png)

A blend of friends and foes illustrating the transformative experience of HACKERSMACKER:

![](http://github.com/samuelclay/HACKERSMACKER/raw/master/docs/screenshot3.png)

## Examples of great Hacker News comments from which to start a collection of friends

 * [http://news.ycombinator.com/item?id=3543440]()
 * [http://news.ycombinator.com/item?id=3576217]()
 * [http://news.ycombinator.com/item?id=3679698]()
 * [http://news.ycombinator.com/item?id=3702513]()

## Acknowledgements

 * **Mihai Parparita** <mihaip@chromium.org> - Help with fixing the issue around browsers not allowing a JSONP AJAX request to modify the page, as it is sandboxed and cannot alter the page using arbitrary JavaScript (the JSONP) not included with the extension itself.
 
## Author

 * **Samuel Clay**: [@samuelclay](http://twitter.com/samuelclay), [samuel@ofbrooklyn.com](mailto:samuel@ofbrooklyn.com), [www.samuelclay.com](http://www.samuelclay.com)
 
## License

 * MIT License
