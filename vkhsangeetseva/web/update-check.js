(async function () {
    const VERSION_CHECK_URL = "/version.json";
    const CACHE_KEY = "app_version";

    try {
        // Fetch the latest version.json
        const response = await fetch(VERSION_CHECK_URL, { cache: "no-store" });
        const latestVersion = await response.json();

        // Get the cached version
        const cachedVersion = localStorage.getItem(CACHE_KEY);

        // Compare versions
        if (cachedVersion && cachedVersion !== latestVersion.version) {
            console.log("New version detected:", latestVersion.version);
            alert("A new version is available. The page will now refresh.");
            localStorage.setItem(CACHE_KEY, latestVersion.version);
            location.reload(true);  // Force refresh
        } else {
            console.log("Running latest version:", latestVersion.version);
            localStorage.setItem(CACHE_KEY, latestVersion.version);
        }
    } catch (error) {
        console.error("Error checking app version:", error);
    }
})();
