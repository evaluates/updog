---
layout: post
title: "Deploying Jekyll Sites"
---

<div class='notice' style='margin-top:10px;'>
  Note: a Pro membership is required to configure a document root.
</div>

[Jekyll](https://jekyllrb.com/) is a static site generator that transforms
your plain text into static websites and blogs.

You can install Jekyll on your own system, and get up and running with a few
terminal commands:

```
$ gem install jekyll
$ jekyll new my_project_name
$ jekyll serve
```

In this post, we'll walk through the process of deploying a jekyll site using
UpDog, like this one - <https://jekyll.updog.co/>

### Create A New UpDog Site

Visit <https://updog.co/new> and create a new site.

Once the site has been created, click on "Settings" and update the document root.

By default, Jekyll compiles all content to a directory named `_site`. Set this
as the document root and click "Save"

### Initialize the project in your Dropbox Folder

Once you’ve created your site on UpDog.co, navigate to your site folder in `~/Dropbox/Apps/updog/<name-of-your-site-here>`

```
$ jekyll new .
$ jekyll build
```

### That's it!

Here's the completed example: <https://jekyll.updog.co/>
