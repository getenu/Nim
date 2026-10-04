discard """
  matrix: "-d:nimVmExecHooks"
  output: '''
paused
55
'''
  joinable: false
"""

## Pauses a script from the VM enter hook and resumes it where it stopped.

import "../../compiler" / [ast, vmdef, vm, nimeval]
import std / os

type Pause = object of CatchableError

let std = findNimStdLibCompileTime()
let i = createInterpreter("pausable.nim",
  [std, parentDir(currentSourcePath), std / "pure", std / "core"])
i.evalScript()

var
  count = 0
  ctx: PCtx
  pausedPc: int
  pausedTos: PStackFrame

i.registerEnterHook proc (c: PCtx; pc: int; tos: PStackFrame; instr: TInstr) =
  inc count
  if count == 20:
    (ctx, pausedPc, pausedTos) = (c, pc, tos)
    raise newException(Pause, "paused")

try:
  discard i.callRoutine(i.selectRoutine("run"), [])
  doAssert false, "script should have paused"
except Pause:
  echo "paused"

doAssert i.getGlobalValue(i.selectUniqueSymbol("total")).intVal < 55
discard resumeExecution(ctx, pausedPc, pausedTos)
echo i.getGlobalValue(i.selectUniqueSymbol("total")).intVal
i.destroyInterpreter()
