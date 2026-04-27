(* Welford's online algorithm for rolling mean and variance *)
type welford_state = {
  n    : int;
  mean : float;
  m2   : float;
}

let welford_empty = { n = 0; mean = 0.0; m2 = 0.0 }

let welford_update state x =
  let n      = state.n + 1 in
  let delta  = x -. state.mean in
  let mean   = state.mean +. delta /. float_of_int n in
  let delta2 = x -. mean in
  let m2     = state.m2 +. delta *. delta2 in
  { n; mean; m2 }

let welford_variance state =
  if state.n < 2 then None
  else Some (state.m2 /. float_of_int (state.n - 1))

let welford_std state =
  match welford_variance state with
  | None   -> None
  | Some v -> Some (sqrt v)

(* Z-score normalization *)
let zscore mean std x =
  if std = 0.0 then 0.0
  else (x -. mean) /. std

(* Pearson correlation between two float arrays *)
let pearson xs ys =
  let n = Array.length xs in
  if n <> Array.length ys || n = 0 then None
  else
    let mean arr =
      Array.fold_left (+.) 0.0 arr /. float_of_int n
    in
    let mx = mean xs in
    let my = mean ys in
    let num = ref 0.0 in
    let dx2 = ref 0.0 in
    let dy2 = ref 0.0 in
    for i = 0 to n - 1 do
      let dx = xs.(i) -. mx in
      let dy = ys.(i) -. my in
      num := !num +. dx *. dy;
      dx2 := !dx2 +. dx *. dx;
      dy2 := !dy2 +. dy *. dy
    done;
    let denom = sqrt (!dx2 *. !dy2) in
    if denom = 0.0 then None
    else Some (!num /. denom)

(* OLS linear regression: y = beta * x + alpha *)
(* Returns (alpha, beta) *)
let ols xs ys =
  let n = Array.length xs in
  if n <> Array.length ys || n < 2 then None
  else
    let mean arr =
      Array.fold_left (+.) 0.0 arr /. float_of_int n
    in
    let mx = mean xs in
    let my = mean ys in
    let num = ref 0.0 in
    let den = ref 0.0 in
    for i = 0 to n - 1 do
      let dx = xs.(i) -. mx in
      num := !num +. dx *. (ys.(i) -. my);
      den := !den +. dx *. dx
    done;
    if !den = 0.0 then None
    else
      let beta  = !num /. !den in
      let alpha = my -. beta *. mx in
      Some (alpha, beta)
