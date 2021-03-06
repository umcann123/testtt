(*Generated by Lem from debug.lem.*)
open HolKernel Parse boolLib bossLib;
val _ = numLib.prefer_num();



val _ = new_theory "lem_debug"



(* debugging functions; these should *not* be used in production code,
   but are invaluable in debugging the OCaml extraction, as long as
   one pays attention to the interaction with monads;
   the typical use pattern is:
     let _ = Debug.print_string "..." in
     ...

   With monads, the "let _" should be out of the monad, not wrapped
   inside the monad (otherwise, the evaluation order is that of the
   monad).
*)

(*val print_string : string -> unit*)
val _ = Define `
 ((print_string:string -> unit) str=  () )`;


(*val print_endline : string -> unit*)
val _ = Define `
 ((print_endline:string -> unit) str=  () )`;

val _ = export_theory()

