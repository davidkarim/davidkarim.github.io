---
layout: post
title:  "WordPress Migration"
date:   2024-11-01 08:00:00 -0400
categories: projects
---

<img src="/assets/images/saintjohn.jpg" alt="Alt text for the image" style="float: left; width: 400px; margin-right: 25px; margin-bottom: 10px;">

The Saint John website originally existed as a WordPress site that had not been updated in several years. The parish had attempted to create a more updated website but was trying to implement it using pure HTML and CSS without considering other factors. For example, they already had a company which provided WordPress hosting for them and would likely have difficulties changing their deployment, backup, and support processes. The church did not want to take on another provider or any additional expense.

I suggested to them that they could continue to use WordPress, but that it would likely be best to create a new site using more modern templates. I created a temporary WordPress server to create an initial mockup we could work with. After getting the main page and the menu structure in place, I had the hosting provider spin up a new WordPress site and I migrated the site over to their server while continuing to have the public DNS point to the old website. 

Once the church was satisfied with the new site, we had the provider update the DNS to make the site go live. The new site implements features such as a Calendar of Events, announcements banner, and a background video which I recorded using a DJI drone. The finished product can be seen here: <a href="https://saintjohn-bocaraton.com" target="_blank" rel="noopener noreferrer">Saint John</a>