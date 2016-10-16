---
layout: post
---

<div class='notice' style='margin-top:10px;'>
  Note: a Pro membership is required to configure a document root.
</div>

[Middleman](https://middlemanapp.com/) is a static site generator using all the
shortcuts and tools in modern web development.

You can install middleman on your own system, and get up and running with a few
terminal commands:

```
$ gem install middleman
$ middleman init my_project_name
$ middleman serve
```

In this post, we'll walk through the process of deploying a middleman site using
UpDog, like this one - https://middleman.updog.co/

### Create A New UpDog Site

Visit <https://updog.co/new> and create a new site.

Once the site has been created, click on "Settings" and update the document root.

By default, middleman compiles all content to a directory named `build`. Set this
as the document root and click "Save":

![](https://dl.dropbox.com/s/64iubufgnagztnh/Screenshot%202016-10-16%2016.53.40.png?dl=0)

### Initialize the project in your Dropbox Folder

Once you’ve created your site, navigate to your site folder in `~/Dropbox/Apps/updog/<name-of-your-site-here>`

```
$ middleman init .
$ middleman build
```

### That's it!

Here's the completed example: <https://middleman.updog.co/>
