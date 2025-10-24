# Clear Browser Cache for Frontend Update

## The Issue

The frontend has been updated with CORS fixes, but your browser is still using the **cached old JavaScript** files.

## Solution: Hard Refresh

### For Chrome / Edge:

1. Open http://localhost:3000
2. Press **Ctrl + Shift + R** (Windows) to hard refresh
   - OR Press **Ctrl + F5**
   - OR Right-click the refresh button → Click "Empty Cache and Hard Reload"

### For Firefox:

1. Open http://localhost:3000
2. Press **Ctrl + Shift + R** (Windows) to hard refresh
   - OR Press **Ctrl + F5**

### Alternative: Open DevTools First

1. Press **F12** to open DevTools
2. Right-click the **Refresh button** in the browser toolbar
3. Select **"Empty Cache and Hard Reload"** (Chrome/Edge) or **"Hard Reload"** (Firefox)

### Nuclear Option: Clear All Cache

If the above doesn't work:

**Chrome/Edge:**

1. Press **Ctrl + Shift + Delete**
2. Select "Cached images and files"
3. Time range: "Last hour"
4. Click "Clear data"
5. Refresh the page

**Firefox:**

1. Press **Ctrl + Shift + Delete**
2. Check "Cache"
3. Time range: "Last hour"
4. Click "Clear Now"
5. Refresh the page

## After Clearing Cache

You should see the new frontend with the updated axios configuration that includes `withCredentials: true`.

## Verify the Fix

1. Open DevTools (F12)
2. Go to **Network** tab
3. Try to register a user
4. Look for the `register` request
5. Check the **Request Headers** section
6. You should now see cookies/credentials being sent

## What Changed

The frontend now includes:

```typescript
const api = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true, // ✅ This enables credentials for CORS
});
```

This allows the browser to send credentials (cookies, authorization headers) with cross-origin requests.
