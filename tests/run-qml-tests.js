#!/usr/bin/env node

"use strict";

const {
    copyFileSync,
    existsSync,
    mkdirSync,
    mkdtempSync,
    readFileSync,
    rmSync,
    writeFileSync,
} = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");

const PASS_MARKER = "QML_TEST_PASS:";
const FAIL_MARKER = "QML_TEST_FAIL:";
const COMPLETE_MARKER = "QML_TEST_SUITE_COMPLETE";
const DESTROYED_OBJECT_WARNING = /(?:destroyed|already deleted|wrapped C\/C\+\+ object of type .* has been deleted|Cannot assign to non-existent property)/i;
const DEFAULT_TIMEOUT_MS = 20_000;

function defaultShellPath() {
    return path.join(__dirname, "qml", "taskbar-model", "shell.qml");
}

function markerText(stdout, stderr) {
    return `${stdout}\n${stderr}`;
}

function hasMarker(text, marker) {
    return text.split(/\r?\n/).some(line => line.includes(marker));
}

function prepareScenario(shellPath, temporaryConfig) {
    // Quickshell's module sandbox disallows imports outside the config folder.
    // Place production components and the scenario in one temporary config root.
    const scenarioRoot = path.join(temporaryConfig, "scenario");
    mkdirSync(scenarioRoot, { recursive: true });
    for (const file of ["TaskbarModel.qml", "WorkspaceRecord.qml", "EntryRecord.qml", "TaskbarModel.js"]) {
        const source = path.join(__dirname, "..", file);
        if (existsSync(source)) copyFileSync(source, path.join(scenarioRoot, file));
    }
    const stagedShell = path.join(scenarioRoot, "shell.qml");
    const source = readFileSync(shellPath, "utf8");
    writeFileSync(stagedShell, source.replace('import "../../../" as Production', 'import "." as Production'));
    return stagedShell;
}

function finishResult(result, temporaryConfig) {
    if (temporaryConfig) {
        rmSync(temporaryConfig, { recursive: true, force: true });
    }
    return result;
}

/**
 * Run the standalone production-QML integration scenario.
 *
 * The returned object is intentionally data-oriented so Node tests can exercise
 * missing executables, non-zero exits, assertion markers, and timeouts without
 * having to catch implementation-specific child_process errors.
 */
function runQmlSuite(options = {}) {
    const shellPath = path.resolve(options.shellPath || defaultShellPath());
    const executable = options.executable
        || process.env.QS_TEST_EXECUTABLE
        || process.env.QS_EXECUTABLE
        || "qs";
    const timeoutMs = Number.isFinite(options.timeoutMs)
        ? Math.max(1, options.timeoutMs)
        : DEFAULT_TIMEOUT_MS;
    const extraArgs = Array.isArray(options.extraArgs) ? options.extraArgs : [];
    const temporaryConfig = mkdtempSync(path.join(os.tmpdir(), "unified-taskbar-qml-"));
    const stagedShellPath = Array.isArray(options.args)
        ? shellPath
        : prepareScenario(shellPath, temporaryConfig);
    const args = Array.isArray(options.args)
        ? options.args.slice()
        : ["-p", stagedShellPath, ...extraArgs];
    const environment = {
        ...process.env,
        ...(options.env || {}),
        // Keep this suite independent of a user's running Quickshell config.
        XDG_CONFIG_HOME: options.env?.XDG_CONFIG_HOME || temporaryConfig,
        QT_QPA_PLATFORM: options.env?.QT_QPA_PLATFORM || "offscreen",
        QT_QUICK_BACKEND: options.env?.QT_QUICK_BACKEND || "software",
        QML_TEST_MODE: "1",
        NO_COLOR: "1",
    };

    if (!existsSync(shellPath) && !options.allowMissingShell) {
        return Promise.resolve(finishResult({
            ok: false,
            reason: "missing-shell",
            error: new Error(`QML scenario does not exist: ${shellPath}`),
            code: null,
            signal: null,
            stdout: "",
            stderr: "",
            timedOut: false,
        }, temporaryConfig));
    }

    return new Promise(resolve => {
        let child;
        let stdout = "";
        let stderr = "";
        let settled = false;
        let timedOut = false;
        let timer;

        const settle = (result) => {
            if (settled) return;
            settled = true;
            if (timer) clearTimeout(timer);
            resolve(finishResult({
                ...result,
                stdout,
                stderr,
                timedOut,
            }, temporaryConfig));
        };

        try {
            child = spawn(executable, args, {
                cwd: options.cwd || path.dirname(shellPath),
                env: environment,
                stdio: ["ignore", "pipe", "pipe"],
                windowsHide: true,
            });
        } catch (error) {
            settle({
                ok: false,
                reason: "spawn-error",
                error,
                code: null,
                signal: null,
            });
            return;
        }

        child.stdout.on("data", chunk => { stdout += chunk.toString(); });
        child.stderr.on("data", chunk => { stderr += chunk.toString(); });
        child.once("error", error => {
            settle({
                ok: false,
                reason: error.code === "ENOENT" ? "missing-executable" : "spawn-error",
                error,
                code: null,
                signal: null,
            });
        });
        child.once("close", (code, signal) => {
            if (settled) return;
            const output = markerText(stdout, stderr);
            if (timedOut) {
                settle({ ok: false, reason: "timeout", error: null, code, signal });
                return;
            }
            if (hasMarker(output, FAIL_MARKER)) {
                settle({
                    ok: false,
                    reason: "qml-assertion-failed",
                    error: null,
                    code,
                    signal,
                });
                return;
            }
            if (DESTROYED_OBJECT_WARNING.test(output)) {
                settle({
                    ok: false,
                    reason: "destroyed-object-warning",
                    error: null,
                    code,
                    signal,
                });
                return;
            }
            if (!hasMarker(output, COMPLETE_MARKER)) {
                settle({
                    ok: false,
                    reason: "missing-suite-complete-marker",
                    error: null,
                    code,
                    signal,
                });
                return;
            }
            if (code !== 0 || signal) {
                settle({
                    ok: false,
                    reason: "non-zero-exit",
                    error: null,
                    code,
                    signal,
                });
                return;
            }
            settle({ ok: true, reason: null, error: null, code, signal });
        });

        timer = setTimeout(() => {
            if (settled) return;
            timedOut = true;
            child.kill("SIGTERM");
            // A QML process should terminate promptly. The second signal keeps a
            // broken runtime from making the Node test hang forever.
            setTimeout(() => {
                if (!settled && child.exitCode === null) child.kill("SIGKILL");
            }, Math.min(500, timeoutMs));
        }, timeoutMs);
    });
}

async function main() {
    const result = await runQmlSuite();
    if (result.stdout) process.stdout.write(result.stdout);
    if (result.stderr) process.stderr.write(result.stderr);
    if (!result.ok) {
        const details = result.error ? `: ${result.error.message}` : "";
        console.error(`QML suite failed (${result.reason}${details})`);
        return 1;
    }
    return 0;
}

if (require.main === module) {
    main().then(code => process.exitCode = code);
}

module.exports = {
    COMPLETE_MARKER,
    DEFAULT_TIMEOUT_MS,
    FAIL_MARKER,
    PASS_MARKER,
    defaultShellPath,
    hasMarker,
    main,
    runQmlSuite,
    // Alias retained for callers that describe this as a runner rather than a suite.
    runQmlTests: runQmlSuite,
};
