(*Generated by Sail from riscv_duopod.*)
Require Import Sail.Base.
Require Import Sail.Real.
Import ListNotations.
Open Scope string.
Open Scope bool.
Open Scope Z.

Definition bits (n : Z) : Type := mword n.

Inductive regfp  :=
  | RFull : string -> regfp
  | RSlice : (string * {n : Z & ArithFact (n >=? 0)} * {n : Z & ArithFact (n >=? 0)}) -> regfp
  | RSliceBit : (string * {n : Z & ArithFact (n >=? 0)}) -> regfp
  | RField : (string * string) -> regfp.
Arguments regfp : clear implicits.

Definition regfps  : Type := list regfp.

Inductive niafp  :=
  | NIAFP_successor : unit -> niafp
  | NIAFP_concrete_address : bits 64 -> niafp
  | NIAFP_indirect_address : unit -> niafp.
Arguments niafp : clear implicits.

Definition niafps  : Type := list niafp.

Inductive diafp  :=
  | DIAFP_none : unit -> diafp | DIAFP_concrete : bits 64 -> diafp | DIAFP_reg : regfp -> diafp.
Arguments diafp : clear implicits.

Inductive a64_barrier_domain := A64_FullShare | A64_InnerShare | A64_OuterShare | A64_NonShare.
Scheme Equality for a64_barrier_domain.
Instance Decidable_eq_a64_barrier_domain :
forall (x y : a64_barrier_domain), Decidable (x = y) :=
Decidable_eq_from_dec a64_barrier_domain_eq_dec.

Inductive a64_barrier_type := A64_barrier_all | A64_barrier_LD | A64_barrier_ST.
Scheme Equality for a64_barrier_type.
Instance Decidable_eq_a64_barrier_type :
forall (x y : a64_barrier_type), Decidable (x = y) :=
Decidable_eq_from_dec a64_barrier_type_eq_dec.

Inductive cache_op_kind :=
  Cache_op_D_IVAC
  | Cache_op_D_ISW
  | Cache_op_D_CSW
  | Cache_op_D_CISW
  | Cache_op_D_ZVA
  | Cache_op_D_CVAC
  | Cache_op_D_CVAU
  | Cache_op_D_CIVAC
  | Cache_op_I_IALLUIS
  | Cache_op_I_IALLU
  | Cache_op_I_IVAU.
Scheme Equality for cache_op_kind.
Instance Decidable_eq_cache_op_kind :
forall (x y : cache_op_kind), Decidable (x = y) :=
Decidable_eq_from_dec cache_op_kind_eq_dec.

Definition xlen  : Z := 64.
Hint Unfold xlen : sail.

Definition xlen_bytes  : Z := 8.
Hint Unfold xlen_bytes : sail.

Definition xlenbits  : Type := bits 64.

Definition regbits  : Type := bits 5.

Inductive iop := RISCV_ADDI | RISCV_SLTI | RISCV_SLTIU | RISCV_XORI | RISCV_ORI | RISCV_ANDI.
Scheme Equality for iop.
Instance Decidable_eq_iop :
forall (x y : iop), Decidable (x = y) :=
Decidable_eq_from_dec iop_eq_dec.

Inductive ast  :=
  | ITYPE : (bits 12 * regbits * regbits * iop) -> ast | LOAD : (bits 12 * regbits * regbits) -> ast.
Arguments ast : clear implicits.

Inductive register_value  :=
  | Regval_vector : list register_value -> register_value
  | Regval_list : list register_value -> register_value
  | Regval_option : option register_value -> register_value
  | Regval_bit : bitU -> register_value
  | Regval_bitvector_64_dec : mword 64 -> register_value.
Arguments register_value : clear implicits.

Record regstate  := { Xs : vec (mword 64) 32; nextPC : mword 64; PC : mword 64; }.
Arguments regstate : clear implicits.
Notation "{[ r 'with' 'Xs' := e ]}" :=
  match r with Build_regstate _ f1 f2 => Build_regstate e f1 f2 end.
Notation "{[ r 'with' 'nextPC' := e ]}" :=
  match r with Build_regstate f0 _ f2 => Build_regstate f0 e f2 end.
Notation "{[ r 'with' 'PC' := e ]}" :=
  match r with Build_regstate f0 f1 _ => Build_regstate f0 f1 e end.



Definition bit_of_regval (merge_var : register_value) : option bitU :=
   match merge_var with | Regval_bit v => Some v | _ => None end.

Definition regval_of_bit (v : bitU) : register_value := Regval_bit v.

Definition bitvector_64_dec_of_regval (merge_var : register_value) : option (mword 64) :=
   match merge_var with | Regval_bitvector_64_dec v => Some v | _ => None end.

Definition regval_of_bitvector_64_dec (v : mword 64) : register_value := Regval_bitvector_64_dec v.



Definition vector_of_regval {a} n (of_regval : register_value -> option a) (rv : register_value) : option (vec a n) := match rv with
  | Regval_vector v => if n =? length_list v then map_bind (vec_of_list n) (just_list (List.map of_regval v)) else None
  | _ => None
end.

Definition regval_of_vector {a size} (regval_of : a -> register_value) (xs : vec a size) : register_value := Regval_vector (List.map regval_of (list_of_vec xs)).

Definition list_of_regval {a} (of_regval : register_value -> option a) (rv : register_value) : option (list a) := match rv with
  | Regval_list v => just_list (List.map of_regval v)
  | _ => None
end.

Definition regval_of_list {a} (regval_of : a -> register_value) (xs : list a) : register_value := Regval_list (List.map regval_of xs).

Definition option_of_regval {a} (of_regval : register_value -> option a) (rv : register_value) : option (option a) := match rv with
  | Regval_option v => option_map of_regval v
  | _ => None
end.

Definition regval_of_option {a} (regval_of : a -> register_value) (v : option a) := Regval_option (option_map regval_of v).


Definition Xs_ref := {|
  name := "Xs";
  read_from := (fun s => s.(Xs));
  write_to := (fun v s => ({[ s with Xs := v ]}));
  of_regval := (fun v => vector_of_regval 32 (fun v => bitvector_64_dec_of_regval v) v);
  regval_of := (fun v => regval_of_vector (fun v => regval_of_bitvector_64_dec v) v) |}.

Definition nextPC_ref := {|
  name := "nextPC";
  read_from := (fun s => s.(nextPC));
  write_to := (fun v s => ({[ s with nextPC := v ]}));
  of_regval := (fun v => bitvector_64_dec_of_regval v);
  regval_of := (fun v => regval_of_bitvector_64_dec v) |}.

Definition PC_ref := {|
  name := "PC";
  read_from := (fun s => s.(PC));
  write_to := (fun v s => ({[ s with PC := v ]}));
  of_regval := (fun v => bitvector_64_dec_of_regval v);
  regval_of := (fun v => regval_of_bitvector_64_dec v) |}.

Local Open Scope string.
Definition get_regval (reg_name : string) (s : regstate) : option register_value :=
  if string_dec reg_name "Xs" then Some (Xs_ref.(regval_of) (Xs_ref.(read_from) s)) else
  if string_dec reg_name "nextPC" then Some (nextPC_ref.(regval_of) (nextPC_ref.(read_from) s)) else
  if string_dec reg_name "PC" then Some (PC_ref.(regval_of) (PC_ref.(read_from) s)) else
  None.

Definition set_regval (reg_name : string) (v : register_value) (s : regstate) : option regstate :=
  if string_dec reg_name "Xs" then option_map (fun v => Xs_ref.(write_to) v s) (Xs_ref.(of_regval) v) else
  if string_dec reg_name "nextPC" then option_map (fun v => nextPC_ref.(write_to) v s) (nextPC_ref.(of_regval) v) else
  if string_dec reg_name "PC" then option_map (fun v => PC_ref.(write_to) v s) (PC_ref.(of_regval) v) else
  None.

Definition register_accessors := (get_regval, set_regval).


Definition MR a r := monadR register_value a r unit.
Definition M a := monad register_value a unit.
