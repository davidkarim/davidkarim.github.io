---
layout: post
title: OAuth, Authentication vs Authorization, and Google Login in Next.js
date: 2026-11-08
image: /assets/images/2026-11-08-oauth-authentication-vs-authorization-and-google-login-in-nextjs/header.jpg
categories:
  - instructional
tags:
  - oauth
  - authentication
  - nextjs
  - google
---

![](/assets/images/2026-11-08-oauth-authentication-vs-authorization-and-google-login-in-nextjs/header.jpg){: style="border-radius: 20px;"}

Login, OAuth, authentication, and authorization get used as if they mean the same thing. They do not, and treating them as one idea is how you end up with an app that can sign someone in but has no clear answer for what that person is allowed to do.

In this post I will cover the concepts first, then the practical piece:

- What authentication and authorization actually mean
- What OAuth is, what it is not, and how OpenID Connect fits in
- What roles Okta and Google play
- Which library I would use to add Google Login to a Next.js app
- How to set that integration up, including the operational details that usually cause the first outage

If you are about to drop a “Sign in with Google” button into a Next.js app, it helps to know what that button is doing before you copy a snippet into `app/`.

---

## Authentication vs authorization

**Authentication** answers one question: who is this?

**Authorization** answers a different question: what is this person allowed to do?

A familiar ops example is a Linux box. Logging in with your SSH key is authentication. The server now knows which user you are. Being listed in `sudoers`, having access to a particular database role, or being allowed through a security group is authorization. You can authenticate successfully and still be denied the action you wanted.

The same split shows up everywhere:

- A badge getting you through the front door is authentication. The badge reader on the server room is authorization.
- A valid AWS console login is authentication. An IAM policy that allows `s3:GetObject` on one bucket and denies everything else is authorization.
- A valid session cookie in a web app means the app knows who you are. A role, group, feature flag, or ownership check decides whether you can see a customer record or trigger a deploy.

People shorten both of these to “auth,” which is where the confusion starts. In conversation that shorthand is fine. In a system design it is not. If you only implement authentication, every signed-in user looks the same. If you only think about authorization, you have no reliable way to know who the actor is.

A few consequences that matter in real applications:

- Authentication should happen as little as you can get away with. The user proves who they are, you establish a session, and you reuse that session.
- Authorization should happen often. Every protected page, API route, and server action needs to ask whether *this* user can do *this* thing.
- A successful login is not a permission grant. “They signed in with Google” does not mean they should see admin pages, other users’ data, or Google Drive files they never agreed to share.

When someone says “we need to add auth,” it is worth asking which half they mean. Sometimes they want a login button. Sometimes they want SSO for employees. Sometimes they want fine-grained permissions. Those are different designs.

---

## What OAuth actually is

[OAuth 2.0](https://oauth.net/2/) is an **authorization** framework. It exists so a user can grant your application limited access to an account they already have, without giving you their password.

That last part is the original point. Before OAuth, a third-party app that needed access to your Google data would ask for your Google password. That is a terrible design. OAuth replaces “give me your password” with “send the user to Google, let Google ask for consent, then give the app a token that only covers what the user approved.”

OAuth has a few standard roles, and the names are worth knowing because they show up in every provider’s docs:

- The **resource owner** is the user.
- The **client** is your application.
- The **authorization server** is the system that authenticates the user and issues tokens. For Google Login, this is Google. For a company SSO setup, it is often Okta.
- The **resource server** is the API being accessed. That might be Gmail or Drive, or it might be your own API if you are validating tokens yourself.

### The authorization code flow

The flow you should use for a server-side Next.js app is the authorization code flow.

1. The user clicks “Sign in with Google” in your app.
2. Your app redirects them to Google, along with your client ID, a redirect URI, and the scopes you want.
3. Google authenticates the user if they are not already signed in. That step is authentication, and it happens on Google’s side, not in your app.
4. Google shows a consent screen if needed, so the user can approve what your app is asking for.
5. Google redirects the user back to your app with a short-lived **authorization code**.
6. Your server exchanges that code for tokens, using your client secret. This exchange happens server-to-server, which is why the user’s browser never needs to see the client secret.
7. Your app receives tokens and can now either create a local session, call a Google API, or both.

If you have been around long enough, you may remember the implicit flow, where tokens were returned directly in the URL fragment. Do not use that. The authorization code flow is the current standard, and public clients should also use [PKCE](https://oauth.net/2/pkce/) so an intercepted code cannot be exchanged by someone else. A Next.js app with a server-side route handler is a confidential client because it can keep a client secret. You should still treat that secret like any other production credential.

### What the tokens mean

- An **access token** is authorization. It lets your app call an API within the scopes the user approved. It is usually short-lived.
- A **refresh token** lets your app request a new access token later without sending the user through the consent screen every time. Google typically issues a refresh token only the first time the user consents, unless you force a new consent prompt.
- An **ID token** comes from [OpenID Connect (OIDC)](https://openid.net/connect/), which sits on top of OAuth 2.0. The ID token is a signed assertion of identity: subject identifier, email, name, and similar claims. That is how a Google sign-in becomes authentication for *your* app, not just permission to call Google’s APIs.

This distinction matters. If you only needed to read a user’s Google Calendar, you would care about OAuth scopes and an access token. If you need a logged-in session in your own Next.js app, you care about the identity information and how you turn that into a session you control.

### Scopes are authorization decisions

Scopes are the permissions your app is requesting. They are easy to treat as a boilerplate list, but they are an authorization decision the user has to approve.

For Google Login, the identity scopes are usually enough:

- `openid`
- `email`
- `profile`

That combination tells Google you want to know who the user is. It does not give you access to Gmail, Drive, Calendar, or anything else in their Google account.

If your app later needs Drive access, that is a separate authorization request. Do not bake `https://www.googleapis.com/auth/drive.file` into the original login just because you might want it someday. Users are more likely to abandon a consent screen that asks for more than the app is obviously doing, and you should not be holding unused grants.

### What OAuth is not

A few things OAuth is often mistaken for:

- It is not a login protocol by itself. Login is the OIDC layer on top, or a session your app creates after it trusts the identity token.
- It is not a permissions system for your own application data. Google can tell you who the user is, and it can authorize access to Google APIs. It does not know whether that user should edit invoice 123 in your database.
- It does not replace session handling. After the callback, you still need a session, cookie, or token strategy in your own app.
- It does not mean you should store Google access tokens in localStorage or log them. Treat them like secrets.

Two operational details that cause most first-time failures:

- Redirect URIs must match exactly, including scheme, host, path, and trailing slash. Google will reject the request with `redirect_uri_mismatch` if they do not.
- Client secrets belong on the server, in environment variables, not in frontend code or git.

---

## Where Okta and Google fit

Google and Okta can both act as an identity provider. In an OAuth/OIDC flow, your app does not collect the user’s password. It redirects the user to the provider, the provider authenticates them, and your app receives tokens it can verify.

They overlap, but they are usually used for different jobs.

### Google

For most public apps, Google means **Sign in with Google**. The user already has a Google account. Your app does not want to store another password. Google authenticates the user and returns identity information through OIDC. If you requested API scopes, Google also returns access tokens that authorize calls to those Google APIs.

Google also appears in company environments through Google Workspace. In that case Google is still the identity provider, but the accounts belong to the organization. You can restrict sign-in to a Workspace domain, which is useful for internal tools. That restriction is an authorization policy sitting on top of Google authentication: “they must be a Google user, and they must belong to this domain.”

So Google can play two related roles:

- As an identity provider, it answers who the user is.
- As an authorization server for Google APIs, it answers whether your app may call Gmail, Drive, Calendar, and similar services on that user’s behalf.

What Google does not do, at least not by default, is manage the permissions inside your product. It will not tell you who an admin is in your SaaS app, which tenants they belong to, or whether they can approve a payroll run.

### Okta

Okta is usually the enterprise identity layer. Companies use it for workforce SSO, MFA, user lifecycle, and deciding which applications a person can open. In that setup, employees do not sign into each internal tool separately. They sign into Okta, and Okta issues tokens your apps trust.

Okta can authenticate users itself with a password plus MFA, passwordless options, or similar. It can also federate to another provider, including Google. That is a common pattern: the employee clicks into an internal app, lands on Okta, and Okta may then send them to Google Workspace to prove who they are. From your app’s point of view, Okta is still the identity provider. Your app should validate Okta’s tokens, not talk to Google directly.

On the authorization side, Okta is often the source of truth for groups, roles, and application assignments. A user might be in an `engineering` group and assigned to your app, or they might be authenticated but not assigned to that app at all. Okta can also act as an OAuth authorization server for your own APIs, issuing access tokens with scopes and claims your backend can enforce.

Okta also has a customer-identity side, where it provides login, social identity, and related features for an application’s end users rather than employees. The same building blocks show up there: authentication at Okta, tokens for your app, and policies for who can access what.

### How to choose

A simple way to think about it:

- If you are building a public or customer-facing Next.js app and you want low-friction login, Google Login is a common fit. The user already has an account, and you do not need to become a password database on day one.
- If you are building an internal or enterprise app and the company already lives in Okta, Okta should be the identity provider. Users may still reach Okta via Google, but your app should trust Okta.
- You can use both. Okta can sit in front as the SSO broker, with Google as one of the ways a user proves who they are.
- If you need Google API access, that is a Google OAuth problem even if login itself goes through Okta. Those are separate grants.

Neither product replaces the original distinction. Google or Okta can authenticate someone. Your application still has to decide what that person is authorized to do once they are in. Sometimes that decision is as simple as “any signed-in user can see their own dashboard.” Sometimes it is groups from Okta, a role stored in your database, or an email-domain check. Make that decision explicit.

---

## Which library I would use in Next.js

For a new Next.js app that needs Google Login, I would use [Better Auth](https://www.better-auth.com/).

For a long time, the default answer was NextAuth.js, later renamed Auth.js. It still works, and if you already have it in production there is no reason to rip it out just to chase a newer name. The Auth.js project is now maintained by the Better Auth team, and they recommend starting new projects with Better Auth unless you have a specific gap.

Why Better Auth is the better default today:

- It is self-hosted and configured in code. That fits a DevOps workflow better than dropping in a hosted auth product before you need one.
- Google is a built-in social provider, so you are not writing the OAuth handshake, token exchange, or callback handling by hand.
- Users, sessions, and linked accounts live in a database you control.
- The Next.js integration is small: a catch-all API route plus a client helper.
- Features you often need later, such as additional social providers or stronger session handling, are already part of the same system instead of a pile of one-off packages.

A few alternatives, if the requirements are different:

- **Auth.js / NextAuth** if the app already uses it and it is stable. Leave it alone until you have a concrete reason to migrate.
- **Clerk** or a similar hosted service if you want login working quickly and you are comfortable with user records living in someone else’s system.
- **Okta’s own SDK** if Okta is your identity provider. Do not run Google Login and Okta side by side as two sources of truth for the same users.
- **Rolling your own OAuth client** is possible, but you will spend time on redirect handling, CSRF, token storage, session cookies, and edge cases that a maintained library already covers. I would not start there unless I had a very specific constraint.

The rest of this post assumes a new Next.js app that should sign users in with Google, using Better Auth.

---

## How to add Google Login to a Next.js app

This is the hands-on path I would take. The Google Cloud setup is where most of the friction is. The library code itself is fairly small.

### Step 1: Configure the Google OAuth client

In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. Create or select a project.
2. Configure the OAuth consent screen if you have not already. For a side project you can start in testing mode and add your own Google account as a test user. For an internal Workspace app, an internal consent screen avoids the external verification process.
3. Go to **APIs & Services** → **Credentials**.
4. Create an **OAuth client ID** and choose **Web application**.
5. Add authorized JavaScript origins:
   - `http://localhost:3000`
   - `https://your-domain.com`
6. Add authorized redirect URIs:
   - Local: `http://localhost:3000/api/auth/callback/google`
   - Production: `https://your-domain.com/api/auth/callback/google`
7. Copy the client ID and client secret.

A few things that are easy to miss:

- Localhost and production are different redirect URIs. You need both registered before you deploy, or production login will fail even though local login worked.
- The path has to match what the library expects. Better Auth’s default callback is `/api/auth/callback/google`. If you change the auth base path, update Google Cloud to match.
- `http` versus `https` matters. So does `www` versus the apex domain. So does a trailing slash.
- The client secret is a secret. Do not commit it, paste it into a frontend file, or drop it into a screenshot.

If the redirect URI does not match, Google returns `redirect_uri_mismatch`. That error almost always means the callback your app is sending does not match what you registered, or `BETTER_AUTH_URL` is still pointing at localhost after deploy.

### Step 2: Install Better Auth and set environment variables

```bash
npm install better-auth better-sqlite3
```

SQLite is enough to prove the flow locally. Before you take this to production, switch to Postgres or whatever database you already run, using one of Better Auth’s adapters.

Add the following to `.env`:

```bash
BETTER_AUTH_SECRET=  # openssl rand -base64 32
BETTER_AUTH_URL=http://localhost:3000
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

`BETTER_AUTH_SECRET` should be a long random value. You can generate one with:

```bash
openssl rand -base64 32
```

`BETTER_AUTH_URL` should be the public URL of the app. Locally that is `http://localhost:3000`. In production it should be your real HTTPS origin. Better Auth uses this value to construct the callback URL it sends to Google, so a wrong value here looks exactly like a misconfigured redirect URI.

Keep these variables out of git. If you deploy to AWS Amplify, add them in the Amplify console for that app and environment rather than baking them into the build output. I wrote about deploying a Next.js app to Amplify separately; the important part here is that production needs its own `BETTER_AUTH_URL` and its own Google redirect URI.

Then generate or apply the Better Auth schema:

```bash
npx auth@latest migrate
```

Better Auth needs somewhere to store users, sessions, and the linked Google account. The migrate step creates that schema. If you are using an ORM adapter, use the generate flow from the Better Auth docs and review the migration before you apply it.

### Step 3: Create the auth config

Create `lib/auth.ts`:

```ts
import { betterAuth } from "better-auth";
import { nextCookies } from "better-auth/next-js";
import Database from "better-sqlite3";

export const auth = betterAuth({
  database: new Database("./sqlite.db"),
  baseURL: process.env.BETTER_AUTH_URL,
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID as string,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET as string,
    },
  },
  plugins: [nextCookies()],
});
```

A few notes on that file:

- `baseURL` is not optional in practice. If it is missing or still set to localhost in production, Google will reject the callback.
- `nextCookies()` should stay last in the plugin list so cookies are set correctly when you call auth methods from server actions.
- This config only requests Google as a login provider. You are not asking for Drive, Gmail, or other Google API scopes yet.

If you later need to force account selection every time, Better Auth lets you set `prompt: "select_account"` on the Google provider. That is useful on a shared machine, or when you are testing with more than one Google account.

If this is an internal app and only one Workspace domain should be allowed in, set `hd` to that domain on the provider. That is an authorization rule: authenticated Google users outside the domain should not get a session.

### Step 4: Mount the Next.js route handler

Create `app/api/auth/[...all]/route.ts`:

```ts
import { auth } from "@/lib/auth";
import { toNextJsHandler } from "better-auth/next-js";

export const { GET, POST } = toNextJsHandler(auth);
```

This catch-all route is the callback endpoint Google redirects to, and it also handles the rest of the auth API. You generally want to leave it at `/api/auth/[...all]` unless you have a reason to change the base path. If you do change it, update the Google Cloud redirect URI and `BETTER_AUTH_URL` handling to match.

### Step 5: Add a Sign in with Google button

Create `lib/auth-client.ts`:

```ts
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient();
```

Then a small client component:

```tsx
"use client";

import { authClient } from "@/lib/auth-client";

export function GoogleSignInButton() {
  return (
    <button
      onClick={() =>
        authClient.signIn.social({
          provider: "google",
        })
      }
    >
      Sign in with Google
    </button>
  );
}
```

When the user clicks the button, they are redirected to Google, they approve the login, and they come back to your app with a session. Signing out is the other half of that client:

```ts
await authClient.signOut();
```

At this point you have the OAuth/OIDC round trip working: Google authenticated the user, your app received identity information, and Better Auth created a local session.

### Step 6: Read the session on the server

Do not treat “there is a cookie” as proof that someone is signed in. Checking for a cookie is fine as a fast redirect hint, but any protected page or server action should validate the session on the server.

```tsx
import { auth } from "@/lib/auth";
import { headers } from "next/headers";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const session = await auth.api.getSession({
    headers: await headers(),
  });

  if (!session) {
    redirect("/sign-in");
  }

  return <h1>Welcome {session.user.name}</h1>;
}
```

That check is authentication: is there a valid session, and who does it belong to? It is not yet authorization. Once you have `session.user`, you can add the rules that belong to your product:

- Only users with an email on your company domain can continue.
- Only users marked as admins can open `/admin`.
- A user can only read rows that belong to their account or tenant.

Those checks should live in the server code that performs the action, not only in the navigation UI. Hiding a button is not authorization.

If you use Next.js middleware or, on newer versions, a proxy file to redirect anonymous users, treat that as an optimistic check. Better Auth’s own docs are explicit that looking at the session cookie is not a security boundary. Always validate the session again in the page, route handler, or server action.

### Step 7: Keep login separate from Google API access

After login works, it is tempting to add more Google scopes to the same button. I would not do that by default.

Login should ask for identity. Extra access should be requested when a feature actually needs it. Better Auth can request additional Google scopes later through `linkSocial`, for example if the user clicks “Connect Google Drive.” That triggers a new consent flow for those scopes instead of surprising people on day one.

This is the OAuth-versus-login distinction again, in product form. Signing the user in is authentication. Reading their Drive files is authorization for a Google API, and it deserves its own consent.

---

## What “done” looks like in production

A local demo is not the same as a login system you can leave running. Before you call this finished, walk through the operational checklist:

- Production redirect URIs are registered in Google Cloud, not just localhost.
- `BETTER_AUTH_URL` in production is the public HTTPS origin.
- `BETTER_AUTH_SECRET`, `GOOGLE_CLIENT_ID`, and `GOOGLE_CLIENT_SECRET` are set in the hosting environment and not checked into the repo.
- The database is not a leftover SQLite file on a local disk. Use a real database, back it up, and run schema changes through your normal migration process.
- HTTPS is required in production. OAuth callbacks and secure cookies depend on it.
- You have tested sign-in, sign-out, and a second sign-in with the same Google account. The second visit should find the existing user rather than create a duplicate.
- You have tested the failure path: canceling the Google consent screen should not leave the app in a broken state.
- If the app is internal, confirm that accounts outside the allowed domain cannot get a session.

If login works locally and fails after deploy, start with the callback URL. In my experience that is the first thing to inspect, before you assume the library is misbehaving.

---

## Wrapping up

A short recap:

- Authentication is who you are. Authorization is what you can do. A successful login only solves the first one.
- OAuth is an authorization framework for delegated access. It lets a user grant your app limited access without sharing a password.
- “Sign in with Google” uses OAuth plus OpenID Connect. The ID token is how Google tells your app who the user is. Access tokens and scopes are how Google authorizes API calls.
- Google is a common identity provider for social login and Google Workspace, and it is also the authorization server for Google APIs. Okta is typically the enterprise SSO and policy layer. They can work together, but your app should have one source of truth for identity.
- For a new Next.js app, I would use Better Auth, create a Google OAuth client, and add Google Login through Better Auth’s Google social provider. Then I would enforce authorization in the application itself.

Once this is in place, the next useful step is deciding how permissions should work after login: an email-domain restriction, roles in your own database, or claims and groups from an identity provider such as Okta. That is a separate design from the login button, and it is the part most apps need to think about sooner than they expect.
