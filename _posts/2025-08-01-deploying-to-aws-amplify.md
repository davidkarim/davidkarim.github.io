---
layout: post
title: Deploying a Next.js app to AWS Amplify
date: 2025-08-01
image: /assets/images/2025-08-01-deploying-to-aws-amplify/aws-amplify-next.png
categories:
  - infrastructure
tags:
---

![](/assets/images/2025-08-01-deploying-to-aws-amplify/aws-amplify-next.png){: style="border-radius: 20px;"}

# How to Deploy a Next.js Application Using AWS Amplify

Deploying a web application shouldn’t be a bottleneck—it should be fast, cost-effective, and scalable. If you're working with **Next.js**, one of the most popular frameworks for building React applications, there's no better way to deploy than with **AWS Amplify**.

In this post, we'll explore:
- Why AWS Amplify is a great choice for hosting your Next.js app.
- How it compares to other options like Vercel, Netlify, and EC2.
- A simple, step-by-step guide to get your app live with Amplify.

---

## Why Choose AWS Amplify?

**AWS Amplify** is a powerful platform that automates the deployment and hosting of full-stack web apps. For Next.js developers, Amplify brings several key advantages:

### Speed
- **CI/CD built-in**: Connect your GitHub repo and Amplify automatically builds and deploys on every commit.
- **SSR support**: Amplify natively supports Server-Side Rendering (SSR) and Static Site Generation (SSG) for Next.js apps.
- **Global CDN**: Amplify deploys your app to edge locations, ensuring low-latency access around the globe.

### Cost Efficiency
- **Pay for what you use**: No flat monthly fees. You only pay for build time and hosting bandwidth.
- **Generous free tier**: Great for side projects or startups just getting started.
- **No need to manage infrastructure**: Unlike EC2 or Fargate, you don’t need to worry about provisioning or scaling servers.

---

## Amplify vs Other Hosting Solutions

| Feature              | AWS Amplify    | Vercel         | Netlify        | AWS EC2          |
| -------------------- | -------------- | -------------- | -------------- | ---------------- |
| **Ease of Setup**    | Easy           | Very Easy      | Very Easy      | Complex          |
| **SSR Support**      | Yes            | Yes            | Limited        | Yes              |
| **Custom Domains**   | Free HTTPS     | Free HTTPS     | Free HTTPS     | Manual Setup     |
| **Build Automation** | Built-in CI/CD | Built-in CI/CD | Built-in CI/CD | Manual           |
| **Pricing Model**    | Usage-based    | Usage-based    | Usage-based    | Pay-per-instance |
| **Scalability**      | Auto-scaled    | Auto-scaled    | Auto-scaled    | Manual scaling   |

While Vercel (creator of Next.js) is tightly integrated with the framework, Amplify gives you more flexibility with backend services and closer integration with the AWS ecosystem if you already use AWS services like Lambda, S3, DynamoDB, or Cognito.

---

## Step-by-Step: Deploy a Next.js App to AWS Amplify

Here’s how to get your app up and running on Amplify in minutes:

### **Step 1: Push Your App to GitHub**
Ensure your Next.js project is pushed to a Git provider like GitHub, GitLab, or Bitbucket.

If not already done:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-username/your-repo.git
git branch -M master
git push -u origin master
```

### **Step 2: Log into the AWS Amplify Console**
Go to the [AWS Amplify Console](https://console.aws.amazon.com/amplify/home) and click **"Create New App"**.

![](/assets/images/2025-08-01-deploying-to-aws-amplify/amplify-first-step.png){: style="border-radius: 20px;"}
### **Step 3: Connect Your Git Repository**
- Choose GitHub (or your provider of choice) and click on Next.
- Authenticate with GitHub and select your repository and branch.
- In the App Settings you will see Service Role, leave it as default: Create and use a new service role

Amplify will auto-detect that you’re using a Next.js app and prefill the build settings.

If you click on Edit YML File, you’ll see a default `amplify.yml` file like this:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci --cache .npm --prefer-offline
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - .next/cache/**/*
      - .npm/**/*

```
You can tweak this file later if needed.

### **Step 4: Review and Deploy**
- Click **"Next"** and review the build settings.
- Click **"Save and Deploy"**.

Amplify will:
- Clone your repo
- Install dependencies
- Build your app
- Deploy it to a globally distributed CDN

Note that Amplify will select an instance type for you. 

![](/assets/images/2025-08-01-deploying-to-aws-amplify/amplify-instance-size-example.png){: style="border-radius: 20px;"}

### **Step 5: View Your Live Site**
Once deployment finishes, you’ll get a public URL like:

```
https://master.d1234abcd.amplifyapp.com
```

You can customize the domain by attaching a custom domain in the Amplify Console (e.g., `www.myapp.com`).


## Bonus: Add a Custom Domain
To attach your domain:
1. Go to the Amplify Console.
2. Select your app → **"Hosting"** → **"Custom Domains"**
3. Add your domain (e.g., from Route53 or any registrar).
4. Amplify will configure DNS and SSL for free.