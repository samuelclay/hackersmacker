(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window._HS = function(e) {
    return console.log(["HS", e]);
  };

  window.HSGraph = (function() {

    function HSGraph() {
      this.attachRaters = __bind(this.attachRaters, this);      this.decorateComments();
    }

    HSGraph.prototype.decorateComments = function() {
      this.findCurrentUser();
      this.findUsernames();
      this.loadRelationships();
      return this.attachSharers();
    };

    HSGraph.prototype.findCurrentUser = function() {
      return this.me = $('.pagetop a[href^=user]').eq(0).attr('href').replace('user?id=', '');
    };

    HSGraph.prototype.findUsernames = function() {
      return this.usernames = _.uniq($('a[href^=user]').map(function() {
        return $(this).attr('href').replace('user?id=', '');
      }));
    };

    HSGraph.prototype.loadRelationships = function() {
      var data;
      data = {
        u: this.usernames,
        me: this.me
      };
      return $.ajax({
        url: 'http://nb.local.host:3030/load',
        data: data,
        traditional: true,
        success: this.attachRaters
      });
    };

    HSGraph.prototype.attachRaters = function(graph) {
      var $user, _i, _len, _ref, _results;
      this.graph = graph;
      console.log('graph', this.graph);
      _ref = $('.default a[href^=user], .subtext a[href^=user]');
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        $user = _ref[_i];
        _results.push(new HSRater($($user), this.me));
      }
      return _results;
    };

    HSGraph.prototype.attachSharers = function() {};

    return HSGraph;

  })();

  window.HSRater = (function() {

    function HSRater($user, me, username) {
      this.$user = $user;
      this.me = me;
      this.username = username;
      this.collapse = __bind(this.collapse, this);
      this.maybeCollapse = __bind(this.maybeCollapse, this);
      this.expand = __bind(this.expand, this);
      this.username = this.$user.attr('href').replace('user?id=', '');
      this.clear();
      this.build();
      this.attach();
      this.handle();
      return;
    }

    HSRater.prototype.clear = function() {
      return this.$user.siblings('.HS-rater').remove();
    };

    HSRater.prototype.build = function() {
      var $pills, foafFoe, foafFriend, foafStatus, foafTitle, graphStatus;
      foafFriend = !!_.contains(HS.graph.foaf_friends, this.username);
      foafFoe = !!_.contains(HS.graph.foaf_foes, this.username);
      graphStatus = "";
      if (_.contains(HS.graph.friends, this.username)) graphStatus = "HS-friend";
      if (_.contains(HS.graph.foes, this.username)) graphStatus = "HS-foe";
      if (foafFriend) foafStatus = "HS-foaf-friend";
      if (foafFoe) foafStatus = "HS-foaf-foe";
      foafTitle = foafFriend ? 'Friend' : 'Foe';
      $pills = $("<div class=\"HS-rater " + graphStatus + "\" data-username=\"" + this.username + "\">\n  <div class=\"HS-rater-button HS-rater-neutral\"></div>\n  <div class=\"HS-rater-button HS-rater-friend\"></div>\n  <div class=\"HS-rater-button HS-rater-foe\"></div>\n</div>\n<div class=\"HS-foaf " + foafStatus + "\" title=\"" + foafTitle + " of a friend\">\n  <div class=\"HS-foaf-start\"></div>\n  <div class=\"HS-foaf-end\"></div>\n</div>");
      this.rater = $pills.filter('.HS-rater');
      this.foaf = $pills.filter('.HS-foaf');
      this.neutral = $('.HS-rater-neutral', this.rater);
      this.foe = $('.HS-rater-foe', this.rater);
      return this.friend = $('.HS-rater-friend', this.rater);
    };

    HSRater.prototype.attach = function() {
      this.$user.after(this.foaf);
      return this.$user.after(this.rater);
    };

    HSRater.prototype.handle = function() {
      var _this = this;
      this.animationOpts = {
        duration: 300,
        easing: 'easeOutQuint',
        queue: false
      };
      this.rater.filter('.HS-rater').bind('mouseenter', this.expand).bind('mouseleave', this.collapse);
      _.each([this.friend, this.foe, this.neutral], function($button) {
        return $button.bind('click', function(e) {
          return _this.save(e);
        });
      });
    };

    HSRater.prototype.expand = function() {
      clearTimeout(this.collapseTimeout);
      this.rater.animate({
        width: 70
      }, this.animationOpts);
      this.friend.animate({
        left: 24
      }, this.animationOpts);
      return this.foe.animate({
        left: 48
      }, this.animationOpts);
    };

    HSRater.prototype.maybeCollapse = function() {
      var _this = this;
      return this.collapseTimeout = setTimeout(function() {
        if (_this.collapseTimeout) return _this.collapse();
      }, 300);
    };

    HSRater.prototype.collapse = function() {
      this.rater.animate({
        width: 22
      }, this.animationOpts);
      this.friend.animate({
        left: 0
      }, this.animationOpts);
      return this.foe.animate({
        left: 0
      }, this.animationOpts);
    };

    HSRater.prototype.save = function(e) {
      var $target, data;
      $target = $(e.currentTarget);
      if ($target.hasClass('HS-rater-friend')) {
        this.relationship = 'friend';
        HS.graph.friends.push(this.username);
        HS.graph.foes = _.without(HS.graph.foes, this.username);
      } else if ($target.hasClass('HS-rater-foe')) {
        this.relationship = 'foe';
        HS.graph.friends = _.without(HS.graph.friends, this.username);
        HS.graph.foes.push(this.username);
      } else {
        HS.graph.friends = _.without(HS.graph.friends, this.username);
        HS.graph.foes = _.without(HS.graph.foes, this.username);
        this.relationship = 'neutral';
      }
      data = {
        username: this.username,
        me: this.me,
        relationship: this.relationship
      };
      $.ajax({
        url: 'http://nb.local.host:3030/save',
        data: data
      });
      HS.graph.friends.push;
      this.reset();
      return this.resetDuplicates();
    };

    HSRater.prototype.reset = function() {
      this.rater.removeClass('HS-foe');
      this.rater.removeClass('HS-friend');
      this.rater.addClass("HS-" + this.relationship);
      return this.collapse();
    };

    HSRater.prototype.resetDuplicates = function() {
      var $dupe, $dupes, _i, _len, _results;
      $dupes = $("a[href^=\"user?id=" + this.username + "\"]").not(this.$user);
      _results = [];
      for (_i = 0, _len = $dupes.length; _i < _len; _i++) {
        $dupe = $dupes[_i];
        _results.push(new HSRater($($dupe), this.me));
      }
      return _results;
    };

    return HSRater;

  })();

  $(document).ready(function() {
    return window.HS = new HSGraph();
  });

}).call(this);
