#!/usr/bin/env node

"use strict";

const assert = require("node:assert/strict");
const path = require("node:path");
const test = require("node:test");
const {
    COMPLETE_MARKER,
    FAIL_MARKER,
    PASS_MARKER,
    runQmlSuite,
} = require("./run-qml-tests.js");

const shellPath = path.join(__dirname, "qml", "taskbar-model", "shell.qml");
const node = process.execPath;

function fakeNode(code) {
    return {
        executable: node,
        shellPath,
        args: ["-e", code],
    };
}

async function runFake(code, options = {}) {
    return runQmlSuite({
        ...fakeNode(code),
        timeoutMs: options.timeoutMs || 1_000,
    });
}

test("qml_runner_success_requires_complete_marker", async () => {
    const result = await runFake(`console.log(${JSON.stringify(`${PASS_MARKER}lifecycle`)}); console.log(${JSON.stringify(COMPLETE_MARKER)});`);
    assert.equal(result.ok, true, result.stderr);
    assert.equal(result.reason, null);
    assert.match(result.stdout, new RegExp(COMPLETE_MARKER));
});

test("qml_runner_rejects_qml_assertion_marker", async () => {
    const result = await runFake(`console.error(${JSON.stringify(`${FAIL_MARKER}lifecycle: broken`)});`);
    assert.equal(result.ok, false);
    assert.equal(result.reason, "qml-assertion-failed");
});

test("qml_runner_rejects_missing_complete_marker", async () => {
    const result = await runFake(`console.log(${JSON.stringify(`${PASS_MARKER}lifecycle`)});`);
    assert.equal(result.ok, false);
    assert.equal(result.reason, "missing-suite-complete-marker");
});

test("qml_runner_rejects_destroyed_object_warnings", async () => {
    const result = await runFake(`console.error("QObject: wrapped C/C++ object of type EntryRecord has been deleted"); console.log(${JSON.stringify(COMPLETE_MARKER)});`);
    assert.equal(result.ok, false);
    assert.equal(result.reason, "destroyed-object-warning");
});

test("qml_runner_rejects_nonzero_exit_even_with_complete_marker", async () => {
    const result = await runFake(`console.log(${JSON.stringify(COMPLETE_MARKER)}); process.exitCode = 7;`);
    assert.equal(result.ok, false);
    assert.equal(result.reason, "non-zero-exit");
    assert.equal(result.code, 7);
});

test("qml_runner_reports_missing_runtime", async () => {
    const result = await runQmlSuite({
        shellPath,
        executable: path.join(__dirname, "does-not-exist-quickshell"),
        timeoutMs: 1_000,
    });
    assert.equal(result.ok, false);
    assert.equal(result.reason, "missing-executable");
    assert.equal(result.error.code, "ENOENT");
});

test("qml_runner_has_a_bounded_timeout", async () => {
    const started = Date.now();
    const result = await runFake("setTimeout(() => {}, 10_000);", { timeoutMs: 75 });
    const elapsed = Date.now() - started;
    assert.equal(result.ok, false);
    assert.equal(result.reason, "timeout");
    assert.equal(result.timedOut, true);
    assert.ok(elapsed < 2_000, `timeout took ${elapsed}ms`);
});


/* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
