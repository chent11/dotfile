#!/usr/bin/env python3
"""Run a command on a pseudo-terminal and answer its prompts, like expect(1).

    tests/answer-prompts.py 'PROMPT=ANSWER' ... -- COMMAND [ARGS...]

Each answer is typed only once its prompt text has appeared in the output,
so commands that run earlier cannot swallow it. All output is passed
through. Exits with the command's exit code; exits 3 if a prompt never
appeared. CI uses it to drive bootstrap.sh's git identity questions.
"""
import os
import pty
import select
import sys
import time

TIMEOUT = 600  # seconds without any output before giving up


def main() -> int:
    sep = sys.argv.index("--")
    pairs = [arg.split("=", 1) for arg in sys.argv[1:sep]]
    cmd = sys.argv[sep + 1:]

    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)

    seen = b""
    pending = list(pairs)
    last_output = time.monotonic()
    while True:
        ready, _, _ = select.select([fd], [], [], 1)
        if ready:
            try:
                chunk = os.read(fd, 4096)
            except OSError:  # EIO: the child closed the terminal
                break
            if not chunk:
                break
            last_output = time.monotonic()
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
            seen = (seen + chunk)[-4096:]
            if pending and pending[0][0].encode() in seen:
                os.write(fd, pending.pop(0)[1].encode() + b"\n")
                seen = b""
        elif time.monotonic() - last_output > TIMEOUT:
            sys.stderr.write("answer-prompts: no output for %ds, killing\n" % TIMEOUT)
            os.kill(pid, 9)
            break

    _, status = os.waitpid(pid, 0)
    if pending:
        sys.stderr.write("answer-prompts: prompt never appeared: %r\n" % pending[0][0])
        return 3
    return os.waitstatus_to_exitcode(status)


if __name__ == "__main__":
    sys.exit(main())
