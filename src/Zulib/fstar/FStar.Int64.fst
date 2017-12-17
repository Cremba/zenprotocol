module FStar.Int64

let n = 64

open FStar.UInt
open FStar.Mul
open FStar.Option

private type t' = | Mk: v:uint_t n -> t'
type t = t'

let v (x:t) : uint_t n = x.v

let v_inj (x1 x2: t): Lemma (requires (v x1 == v x2))
                            (ensures (x1 == x2)) = ()

val add: a:t -> b:t -> Pure t
  (requires (size (v a + v b) n))
  (ensures (fun c -> v a + v b = v c))
let add a b = Mk (add (v a) (v b))

val add_mod: a:t -> b:t -> Pure t
  (requires True)
  (ensures (fun c -> (v a + v b) % pow2 n = v c))
let add_mod a b = Mk (add_mod (v a) (v b))

val checked_add: a:t -> b:t -> option t
let checked_add a b = map Mk (checked_add (v a) (v b))

(* Subtraction primitives *)
val sub: a:t -> b:t -> Pure t
  (requires (size (v a - v b) n))
  (ensures (fun c -> v a - v b = v c))
let sub a b = Mk (sub (v a) (v b))

val sub_mod: a:t -> b:t -> Pure t
  (requires True)
  (ensures (fun c -> (v a - v b) % pow2 n = v c))
let sub_mod a b = Mk (sub_mod (v a) (v b))

val checked_sub: a:t -> b:t -> option t
let checked_sub a b = map Mk (checked_sub (v a) (v b))

(* Multiplication primitives *)
val mul: a:t -> b:t -> Pure t
  (requires (size (v a * v b) n))
  (ensures (fun c -> v a * v b = v c))
let mul a b = Mk (mul (v a) (v b))

val mul_mod: a:t -> b:t -> Pure t
  (requires True)
  (ensures (fun c -> (v a * v b) % pow2 n = v c))
let mul_mod a b = Mk (mul_mod (v a) (v b))

val checked_mul: a:t -> b:t -> option t
let checked_mul a b = map Mk (checked_mul (v a) (v b))

(*
val mul_div: a:t -> b:t -> Pure t
  (requires True)
  (ensures (fun c -> (v a * v b) / pow2 n = v c))
let mul_div a b = Mk (mul_div (v a) (v b))
*)

(* Division primitives *)
val div: a:t -> b:t{v b <> 0} -> Pure t
  (requires (True))
  (ensures (fun c -> v b <> 0 ==> v a / v b = v c))
let div a b = Mk (div (v a) (v b))

val checked_div: a:t -> b:t -> option t
let checked_div a b = map Mk (checked_div (v a) (v b))

(* Modulo primitives *)
val rem: a:t -> b:t{v b <> 0} -> Pure t
  (requires True)
  (ensures (fun c ->
    v a - ((v a / v b) * v b) = v c))
let rem a b = Mk (mod (v a) (v b))

(*
(* Bitwise operators *)
val logand: t -> t -> Tot t
let logand a b = Mk (logand (v a) (v b))
val logxor: t -> t -> Tot t
let logxor a b = Mk (logxor (v a) (v b))
val logor: t -> t -> Tot t
let logor a b = Mk (logor (v a) (v b))
val lognot: t -> Tot t
let lognot a = Mk (lognot (v a))
*)
val uint_to_t: x:uint_t n -> Pure t
  (requires True)
  (ensures (fun y -> v y = x))
let uint_to_t x = Mk x

#set-options "--lax"
//This private primitive is used internally by the
//compiler to translate bounded integer constants
//with a desugaring-time check of the size of the number,
//rather than an expensive verifiation check.
//Since it is marked private, client programs cannot call it directly
//Since it is marked unfold, it eagerly reduces,
//eliminating the verification overhead of the wrapper
private
unfold
let __uint_to_t (x:int) : t
    = uint_to_t x
#reset-options

(*
(* Shift operators *)
val shift_right: a:t -> s:UInt32.t -> Pure t
  (requires True)
  (ensures (fun c -> UInt32.v s < n ==> v c = (v a / (pow2 (UInt32.v s)))))
let shift_right a s = Mk (shift_right (v a) (UInt32.v s))

val shift_left: a:t -> s:UInt32.t -> Pure t
  (requires True)
  (ensures (fun c -> UInt32.v s < n ==> v c = ((v a * pow2 (UInt32.v s)) % pow2 n)))
let shift_left a s = Mk (shift_left (v a) (UInt32.v s))
*)

(* Comparison operators *)

let eq  (a:t) (b:t) : bool = eq  #n (v a) (v b)
let gt  (a:t) (b:t) : bool = gt  #n (v a) (v b)
let gte (a:t) (b:t) : bool = gte #n (v a) (v b)
let lt  (a:t) (b:t) : bool = lt  #n (v a) (v b)
let lte (a:t) (b:t) : bool = lte #n (v a) (v b)
(*
assume val eq_mask: a:t -> b:t -> Tot (c:t{(v a = v b ==> v c = pow2 n - 1) /\ (v a <> v b ==> v c = 0)})
assume val gte_mask: a:t -> b:t -> Tot (c:t{(v a >= v b ==> v c = pow2 n - 1) /\ (v a < v b ==> v c = 0)})
*)
(* Infix notations *)
unfold let op_Plus_Hat = add
unfold let op_Plus_Percent_Hat = add_mod
unfold let (+?^) = checked_add
unfold let op_Subtraction_Hat = sub
unfold let op_Subtraction_Percent_Hat = sub_mod
unfold let (-?^) = checked_sub
unfold let op_Star_Hat = mul
unfold let op_Star_Percent_Hat = mul_mod
unfold let ( *?^) = checked_mul
//unfold let op_Star_Slash_Hat = mul_div
unfold let op_Slash_Hat = div
unfold let (/?^) = checked_div
unfold let op_Percent_Hat = rem
//unfold let op_Hat_Hat = logxor
//unfold let op_Amp_Hat = logand
//unfold let op_Bar_Hat = logor
//unfold let op_Less_Less_Hat = shift_left
//unfold let op_Greater_Greater_Hat = shift_right
unfold let op_Equals_Hat = eq
unfold let op_Greater_Hat = gt
unfold let op_Greater_Equals_Hat = gte
unfold let op_Less_Hat = lt
unfold let op_Less_Equals_Hat = lte

(* To input / output constants *)
assume val to_string: t -> string
assume val of_string: string -> t
