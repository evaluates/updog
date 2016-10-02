---
layout: post
title: Configuring a Custom Domain with GoDaddy
---

This post is for people who have purchased a domain name from GoDaddy and wish
to use UpDog as their webhost with that domain.

In this guide, we'll show you how to:

- Configure a CNAME alias for your subdomain
- Redirect domain names to www
- Add your custom domain to an UpDog site

I recently purchased a domain name <jshawl.xyz>, which I'll refer to throughout
this guide. Substitute your own domain name where it appears again.

### Configuring a CNAME Alias

In order to let users view my UpDog site when visiting www.jshawl.xyz, I need to
tell GoDaddy that www.jshawl.xyz is an alias (or CNAME) for updog.co.

Log into your GoDaddy Account and select "My Products":

![](https://dl.dropbox.com/s/w0a1g88u80ck5gt/Screenshot%202016-10-02%2018.36.14.png?dl=0)

Then Click on Domains:

![](https://dl.dropbox.com/s/dka3q7enm865joj/Screenshot%202016-10-02%2018.36.46.png?dl=0)

And then click on "Manage DNS" in the bottom right corner:

![](https://dl.dropbox.com/s/n4krgr7xidrlddq/Screenshot%202016-10-02%2018.36.54.png?dl=0)

Click on the edit icon for the www CNAME:

![](https://dl.dropbox.com/s/r5maq6dmrejxecm/Screenshot%202016-10-02%2018.50.36.png?dl=0)

Replace the "@" under Points to with updog.co

![](https://dl.dropbox.com/s/nvuqg86888xrmml/Screenshot%202016-10-02%2018.37.52.png?dl=0)

Click save.

### Redirect your domain name to www.

Unfortunately, it is not currently possible to host bare (or apex) domains with
UpDog. As a result, you'll need to redirect your domain name traffic to www.

Scroll down to the bottom of the page until you see "Forwarding", and click on Add.

![](https://dl.dropbox.com/s/825ws73ef8uuept/Screenshot%202016-10-02%2018.38.14.png?dl=0)

Type in your domain name, including the www.

![](https://dl.dropbox.com/s/0cpjqkif0txnbwq/Screenshot%202016-10-02%2018.38.48.png?dl=0)

Click Save, and you're done!

If you'd like any assistance with the above process, please [contact us](/contact)
and we'll get back to you as soon as possible.
