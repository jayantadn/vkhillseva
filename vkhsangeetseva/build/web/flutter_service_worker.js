'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"index.html": "9dc0153b3f63f3835a8e3263f0777fc6",
"/": "9dc0153b3f63f3835a8e3263f0777fc6",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/images/NityaSeva/tulasi_garland.png": "1381503bf7a6ca9290f10f366287bb2c",
"assets/assets/images/NityaSeva/laddu.png": "88079825d761e0e842126b1e6f1208ff",
"assets/assets/images/NityaSeva/vishnu_pushpanjali.png": "f18aac2713f009607f470315cd3d1612",
"assets/assets/images/NityaSeva/gita.png": "04eb9083ffee9d286f14262454365407",
"assets/assets/images/NityaSeva/sadhu_bhojana.png": "78f6494dd4183cbd3e6786675ba31035",
"assets/assets/images/NityaSeva/sadhu_seva.png": "6a6536834599c1a6932c15ac4a84f4ad",
"assets/assets/images/NityaSeva/tas.png": "7f121a189f748040ffa2925b8f9e8163",
"assets/assets/images/NityaSeva/JalaDana.png": "91a5bce6d50f82f3478bcc20edd9f6c6",
"assets/assets/images/NityaSeva/ShodashopacharaSeva.png": "19055b768044f4bd58c0b412ab8acacc",
"assets/assets/images/NityaSeva/flower_garland.png": "6675b1ca73bfda3a5a5cb4ecf2841bf3",
"assets/assets/images/Logo/KrishnaLilaPark_square.png": "4e2f7741a34167efcaec859c51c4c834",
"assets/assets/images/Logo/SangeetSeva.png": "9cd6dfde4cec409c2815e88f12e7fb2f",
"assets/assets/images/Logo/KrishnaLilaPark_circle.png": "ba0e84b1150a087ec3e7360015f97232",
"assets/assets/images/Festivals/NityanandaTrayodashi.png": "523d76bb5df59a6f67674b03affc4851",
"assets/assets/images/Festivals/RathaYatra.png": "3bfd92d7ffb3f62e887f256203e24396",
"assets/assets/images/Festivals/RamNavami.png": "d24f59c0a40f20775030ed8bace4c470",
"assets/assets/images/Festivals/Balarama.png": "12c1e7bc227a8d6fedfd996e79a30da6",
"assets/assets/images/Festivals/Vamana.png": "1d56b3250b018c893b55fd6c940cb7f0",
"assets/assets/images/Festivals/Govardhana.png": "f2f893a99a776fd95025a4b61fa41bda",
"assets/assets/images/Festivals/VyasaPuja.png": "cb28eba3dfd6d40c9473884d76266da9",
"assets/assets/images/Festivals/Garuda.png": "bd5a56ec3a91a4c82dc25054274938d7",
"assets/assets/images/Festivals/GaurNitai.png": "1b95ee13e304625c37a4695697815506",
"assets/assets/images/Festivals/JhulanUtsava.png": "25db4ad404ffd5385c74d06a77d0dce8",
"assets/assets/images/Festivals/NarasimhaChaturdashi.png": "201642f8a64fa8ad993d8a52e4618278",
"assets/assets/images/Festivals/AkshayaTritiya.png": "16767449ccf7bfa84bc37f2f27b0aef1",
"assets/assets/images/Festivals/HanumanJayanti.png": "9bbae9db2a0a5a5df7576b73f57c8dc1",
"assets/assets/images/PaymentModes/icon_cash.png": "dc5f16b6cf7b939f5182d27bcefa84a2",
"assets/assets/images/PaymentModes/icon_card.png": "41c36bc7c9b3b29ac185d88cc1ddc3f2",
"assets/assets/images/PaymentModes/icon_upi.png": "ddae5488cf352b013ef482aee9c32702",
"assets/assets/images/PaymentModes/icon_gift.png": "a4534722f712e1c05073a4872187a726",
"assets/assets/images/Common/add.png": "65354ed1ea661f0fc5d4389944a33c6b",
"assets/assets/images/Common/morning.png": "1b74e5fe0a3c69cca84bad33626379a8",
"assets/assets/images/Common/evening.png": "cdc80415b8dbdcb960e9878604c67ecf",
"assets/assets/images/LauncherIcons/Deepotsava.png": "21bdac5f3ecf6174e95d3488cea8cbf2",
"assets/assets/images/LauncherIcons/Harinaam.png": "1a8b124a54f33583af5b62aba377a9b6",
"assets/assets/images/LauncherIcons/NityaSeva.png": "91d3269c8819ec0a3a3f7d86159a604d",
"assets/assets/images/VKHillDieties/LakshmiNarasimha.png": "4e80d6c3f0fead5dda4127413dd9036b",
"assets/assets/images/VKHillDieties/Hanuman.png": "083b037c5e03f647553478ad34548a63",
"assets/assets/images/VKHillDieties/RadhaKrishna.png": "53fc255f1fb3308a657ed1acf6807651",
"assets/assets/images/VKHillDieties/Jagannatha.png": "6941dcf36e5755ad8339a8cc1f90177c",
"assets/assets/images/VKHillDieties/NitaiGauranga.png": "797b6762878d2aaa1d92117efab23f56",
"assets/assets/images/VKHillDieties/Narasimha.png": "0538bc297c7e321e8425b72f39d80cad",
"assets/assets/images/VKHillDieties/Sudarshana.png": "09506b4abf4ea26739b29afdad406f3e",
"assets/assets/images/VKHillDieties/Garuda.png": "a260b5c5e3d3630c41843fc3e713d2b4",
"assets/assets/images/VKHillDieties/Govinda.png": "65e3d94c8da254f1d00afc9c300873bc",
"assets/assets/images/VKHillDieties/Prabhupada.png": "1115f235e05b82bbcb307c19a9d6fbd6",
"assets/assets/images/VKHillDieties/Padmavati.png": "b1b95d7b66c05b831b9051f9919b46e6",
"assets/fonts/MaterialIcons-Regular.otf": "17aed1bfea0fdf16a34778d690239c73",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fast_image_resizer/assets/lena.png": "af16d124a7d709df7d8e1cdda7ac6e5a",
"assets/AssetManifest.bin.json": "1d724cc1d35e9d7a3648ac74339da93d",
"assets/AssetManifest.json": "c2608bf178a577673c31bb1c066d248c",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "90b9406eb7b5cab1b604e3e9373dd514",
"assets/NOTICES": "c31bd99ffd0d4f99a79ba98f721a6001",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"main.dart.js": "46330ebaecda24488cb5362a079e450f",
"flutter_bootstrap.js": "5e9b80b05faa9fc79262c4b698ab4209",
"manifest.json": "b8c051eef9b268720f64f9a295a52ea6",
"version.json": "2fc5089a724cd5d2732c43a29d716b27"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
