export const API_URL = 'http://devops-challenge-alb-1970167075.us-east-1.elb.amazonaws.com/api'
export default API_URL

// How your frontend actually reaches that API: Remember frontend/src/config.js, which sets 
// API_URL. Your React code uses that value inside a fetch() call, something like fetch(API_URL) — 
// that's the actual line of JavaScript, running in the user's browser, that goes out and asks 
// the backend for its GUID data. Once deployed to AWS, per the how-to doc, that gets set to 
// "http://<ALB-DNS>/api" — meaning the browser's fetch call is aimed at your ALB, at the /api 
// path specifically.


// How that request actually reaches a real backend task: The ALB receives that request on its port 80 listener. Since 
// the path is /api, it matches the listener rule you set up (path_pattern = ["/api/*"]), which forwards it to the 
// backend target group instead of the default frontend target group. The target group then picks one of the currently 
// healthy backend tasks (server with IP) and hands the request off to it.


// in the context of a website, it usually means a set of URLs a server exposes specifically for exchanging raw data 
// (like your GUID, as JSON), rather than serving actual visual webpages.
// Your backend is an API
// not render any HTML or UI
// That's the core reason they're two separate services in the first place — one serves pages, one serves data.

// Clicking things afterward, inside the app — here's the key difference: in a typical React app, once that initial JS bundle is loaded into the 
// browser, clicking buttons/links usually does not trigger a brand new request to the server for "another webpage." Instead, the JavaScript 
// that's already running in your browser just updates what's on screen directly (swapping components, changing what's displayed) — no round trip 
// to the ALB at all for that part. This is actually the whole point of an SPA: avoid re-fetching a full page for every interaction, for speed. 
// (Exception: if a link points to a totally different domain, or you do a hard browser refresh, that would trigger a fresh full request through 
// the same ALB flow as before.)

// workflow of website (what actions trigger backend requests)
// Initial page load — yes, exactly as we mapped out: browser GET request → ALB → listener (no /api match) → frontend target group → task serves 
// the actual HTML/CSS/JS files. This happens once, when you first arrive at the site.

// // BACKEND REQUESTS
// Fetching data the page doesn't already have. Loading a list of products, search results, a user's profile info, comments on a post — anything the 
// server has to look up and hand back, since the browser doesn't have it sitting in memory already.

// Submitting a form. Logging in, signing up, posting a comment, checking out a cart, submitting a contact form — any time you're sending user-entered 
// data to the server to be saved, validated, or processed.

// Any action that changes stored data. Clicking "like," adding an item to a cart, deleting a post, updating a setting — these all need to tell the 
// server "please remember this change," since the browser alone can't permanently store anything past a page refresh.

// Real-time or "load more" actions. Infinite-scroll loading more posts, a chat app receiving new messages, a live dashboard refreshing numbers — 
// anything continuously pulling fresh data from the server after the initial page already loaded.

// Authentication-related actions. Logging in, logging out, refreshing a session token — checking "is this user actually who they say they are" always 
// requires the server, since that's not something the browser can verify by itself.

// Worth noting for your specific project though: your current app doesn't actually have any buttons or interactive elements at all — the one and only 
// backend request happens automatically, immediately, the instant the page finishes loading (that fetch() call that gets your GUID). There's no 
// user-triggered action involved in this particular app; it's the simplest possible case, just to prove frontend-to-backend connectivity works.

