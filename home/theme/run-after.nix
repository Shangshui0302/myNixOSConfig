# HM's `run` must guard the whole action: shell redirections, mktemp and
# command substitutions would still execute in `run cmd > file` / `run cmd "$(...)"`.
lib: name: after: body:
lib.hm.dag.entryAfter after ''
  ${name}() (
    ${body}
  )
  run ${name}
''
