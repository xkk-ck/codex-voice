#!/usr/bin/env node
"use strict";

const http = require("node:http");
const { spawn } = require("node:child_process");
const path = require("node:path");
const { URL } = require("node:url");

const root = process.env.CODEX_VOICE_ROOT || path.resolve(__dirname, "..");
const port = Number(process.env.CODEX_VOICE_PORT || 47732);
const host = "127.0.0.1";
const insertScript = path.join(root, "scripts", "insert-into-codex-macos.applescript");
const pasteHelperApp =
  process.env.CODEX_VOICE_PASTE_HELPER_APP ||
  path.join(process.env.HOME || "", "Applications", "Codex Voice Helper.app");

function permissionHelp() {
  return {
    hostApp: process.env.CODEX_VOICE_PERMISSION_APP || process.env.TERM_PROGRAM || "Codex Voice Helper",
    settingsUrl: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
    message:
      "macOS does not always show an Accessibility permission prompt. Open System Settings > Privacy & Security > Accessibility and enable Codex Voice Helper, then restart Codex Voice.",
  };
}

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 200_000) {
        reject(new Error("Request body is too large."));
        req.destroy();
      }
    });
    req.on("end", () => resolve(body));
    req.on("error", reject);
  });
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        const error = new Error(stderr.trim() || `${command} exited with ${code}`);
        error.code = code;
        error.stdout = stdout;
        error.stderr = stderr;
        reject(error);
      }
    });
  });
}

async function copyToClipboard(text) {
  const child = spawn("pbcopy", [], { stdio: ["pipe", "ignore", "pipe"] });
  return new Promise((resolve, reject) => {
    let stderr = "";
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(stderr.trim() || `pbcopy exited with ${code}`));
    });
    child.stdin.end(text);
  });
}

async function insertIntoCodex(text, autoSend) {
  if (pasteHelperApp && pasteHelperApp.endsWith(".app")) {
    const textPath = path.join(
      process.env.TMPDIR || "/tmp",
      `codex-voice-${Date.now()}-${Math.random().toString(16).slice(2)}.txt`,
    );
    await require("node:fs/promises").writeFile(textPath, text, "utf8");
    try {
      await run("open", ["-W", "-a", pasteHelperApp, "--args", textPath, autoSend ? "true" : "false"]);
    } finally {
      require("node:fs/promises").unlink(textPath).catch(() => {});
    }
    return;
  }
  await run("osascript", [insertScript, text, autoSend ? "true" : "false"]);
}

async function handlePost(req, res, route) {
  let payload;
  try {
    const raw = await readBody(req);
    payload = raw ? JSON.parse(raw) : {};
  } catch (error) {
    sendJson(res, 400, { ok: false, error: "Invalid JSON body." });
    return;
  }

  const text = typeof payload.text === "string" ? payload.text.trim() : "";
  const autoSend = payload.autoSend === true;

  if (!text) {
    sendJson(res, 400, { ok: false, error: "Missing text." });
    return;
  }

  if (route === "/clipboard") {
    try {
      await copyToClipboard(text);
      sendJson(res, 200, { ok: true, mode: "clipboard" });
    } catch (error) {
      sendJson(res, 500, { ok: false, error: error.message });
    }
    return;
  }

  try {
    await insertIntoCodex(text, autoSend);
    sendJson(res, 200, { ok: true, mode: "accessibility", autoSend });
  } catch (error) {
    try {
      await copyToClipboard(text);
      sendJson(res, 200, {
        ok: true,
        mode: "clipboard",
        needsAccessibility: true,
        permission: permissionHelp(),
        autoSend: false,
        message:
          "Automatic insertion failed; copied to clipboard instead. Enable macOS Accessibility permission to insert directly.",
        detail: error.message,
      });
    } catch (copyError) {
      sendJson(res, 500, {
        ok: false,
        error: "Automatic insertion and clipboard fallback both failed.",
        detail: `${error.message}\n${copyError.message}`,
      });
    }
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${host}:${port}`);

  if (req.method === "OPTIONS") {
    sendJson(res, 200, { ok: true });
    return;
  }

  if (req.method === "GET" && url.pathname === "/health") {
    sendJson(res, 200, {
      ok: true,
      name: "codex-voice-helper",
      root,
      platform: process.platform,
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/permissions") {
    sendJson(res, 200, {
      ok: true,
      permission: permissionHelp(),
    });
    return;
  }

  if (req.method === "POST" && url.pathname === "/open-accessibility-settings") {
    try {
      await run("open", [permissionHelp().settingsUrl]);
      sendJson(res, 200, { ok: true });
    } catch (error) {
      sendJson(res, 500, { ok: false, error: error.message });
    }
    return;
  }

  if (req.method === "POST" && (url.pathname === "/insert" || url.pathname === "/clipboard")) {
    await handlePost(req, res, url.pathname);
    return;
  }

  sendJson(res, 404, { ok: false, error: "Not found." });
});

server.listen(port, host, () => {
  console.log(`Codex Voice Helper listening at http://${host}:${port}`);
});
