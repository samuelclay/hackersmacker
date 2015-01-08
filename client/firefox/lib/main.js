var pageMod = require("sdk/page-mod");
var self = require("sdk/self");
 
pageMod.PageMod({
  include: "https://news.ycombinator.com/*",
  contentStyleFile: self.data.url("client.css"),
  contentScriptFile: [
      self.data.url("injector.js")
  ],
  attachTo: ["existing", "top"],
  onAttach: function(worker) {
    console.log(worker.tab.url);
    worker.port.emit( "init", [
        self.data.url("jq.js"),
        self.data.url("jquery.easing.js"),
        self.data.url("us.js"),
        self.data.url("client.js")
    ]);
  }
});

// Turn on to debug
// var tabs = require("sdk/tabs");
// tabs.open("https://news.ycombinator.com");