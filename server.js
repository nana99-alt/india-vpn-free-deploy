const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const { SocksProxyAgent } = require("socks-proxy-agent");

const root = path.resolve(__dirname, "public");
const port = process.env.PORT || 10000;
const proxyUrl = process.env.SOCKS5_PROXY || "socks5h://141.148.206.170:1088";
const mime = { ".html": "text/html; charset=utf-8", ".css": "text/css; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".svg": "image/svg+xml" };

async function proxyCheck() {
  return new Promise((resolve, reject) => {
    const request = https.get("https://ipinfo.io/json", { agent: new SocksProxyAgent(proxyUrl), headers: { Accept: "application/json" } }, response => {
      let body = "";
      response.setEncoding("utf8");
      response.on("data", chunk => { body += chunk; });
      response.on("end", () => {
        if (response.statusCode < 200 || response.statusCode >= 300) return reject(new Error(`ipinfo returned ${response.statusCode}`));
        try { resolve(JSON.parse(body)); } catch { reject(new Error("invalid ipinfo response")); }
      });
    });
    request.setTimeout(15000, () => request.destroy(new Error("proxy timeout")));
    request.on("error", reject);
  });
}

http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  if (url.pathname === "/health") {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
    return res.end(JSON.stringify({ ok: true, service: "IndiaVPN dashboard", vpnTunnelConfiguredHere: false }));
  }
  if (url.pathname === "/proxy-check") {
    return proxyCheck().then(data => {
      res.writeHead(200, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
      res.end(JSON.stringify({ ok: true, proxy: proxyUrl.replace(/:\/\/.*@/, "://***@"), ipinfo: data }));
    }).catch(error => {
      res.writeHead(502, { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" });
      res.end(JSON.stringify({ ok: false, error: error.message }));
    });
  }
  const requested = url.pathname === "/" ? "index.html" : decodeURIComponent(url.pathname).replace(/^\/+/, "");
  const file = path.resolve(root, requested);
  if (file !== root && !file.startsWith(root + path.sep)) {
    res.writeHead(403); return res.end("Forbidden");
  }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" }); return res.end("Not found"); }
    res.writeHead(200, { "Content-Type": mime[path.extname(file)] || "application/octet-stream", "X-Content-Type-Options": "nosniff" });
    res.end(data);
  });
}).listen(port, "0.0.0.0", () => console.log(`IndiaVPN dashboard listening on ${port}`));
