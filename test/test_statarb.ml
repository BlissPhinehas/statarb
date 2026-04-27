open OUnit2

(* ── Welford tests ── *)

let test_welford_mean _ =
  let state = List.fold_left Stats.welford_update
                Stats.welford_empty [1.0; 2.0; 3.0; 4.0; 5.0] in
  assert_equal ~printer:string_of_float 3.0 state.Stats.mean

let test_welford_variance _ =
  let state = List.fold_left Stats.welford_update
                Stats.welford_empty [2.0; 4.0; 4.0; 4.0; 5.0; 5.0; 7.0; 9.0] in
  match Stats.welford_variance state with
  | None -> assert_failure "Expected variance"
  | Some v -> assert_bool "variance ~4.0" (abs_float (v -. 4.571) < 0.01)

let test_welford_empty _ =
  let state = Stats.welford_empty in
  assert_equal None (Stats.welford_variance state)

(* ── Z-score tests ── *)

let test_zscore_basic _ =
  let z = Stats.zscore 0.0 1.0 1.0 in
  assert_equal ~printer:string_of_float 1.0 z

let test_zscore_zero_std _ =
  let z = Stats.zscore 5.0 0.0 5.0 in
  assert_equal ~printer:string_of_float 0.0 z

(* ── Pearson tests ── *)

let test_pearson_perfect _ =
  let xs = [|1.0; 2.0; 3.0; 4.0; 5.0|] in
  let ys = [|2.0; 4.0; 6.0; 8.0; 10.0|] in
  match Stats.pearson xs ys with
  | None -> assert_failure "Expected correlation"
  | Some r -> assert_bool "r should be ~1.0" (abs_float (r -. 1.0) < 1e-9)

let test_pearson_negative _ =
  let xs = [|1.0; 2.0; 3.0; 4.0; 5.0|] in
  let ys = [|10.0; 8.0; 6.0; 4.0; 2.0|] in
  match Stats.pearson xs ys with
  | None -> assert_failure "Expected correlation"
  | Some r -> assert_bool "r should be ~-1.0" (abs_float (r +. 1.0) < 1e-9)

let test_pearson_mismatched _ =
  let xs = [|1.0; 2.0|] in
  let ys = [|1.0; 2.0; 3.0|] in
  assert_equal None (Stats.pearson xs ys)

(* ── OLS tests ── *)

let test_ols_basic _ =
  let xs = [|1.0; 2.0; 3.0; 4.0; 5.0|] in
  let ys = [|3.0; 5.0; 7.0; 9.0; 11.0|] in
  match Stats.ols xs ys with
  | None -> assert_failure "Expected OLS result"
  | Some (alpha, beta) ->
    assert_bool "alpha ~1.0" (abs_float (alpha -. 1.0) < 1e-9);
    assert_bool "beta ~2.0"  (abs_float (beta  -. 2.0) < 1e-9)

let test_ols_too_short _ =
  let xs = [|1.0|] in
  let ys = [|2.0|] in
  assert_equal None (Stats.ols xs ys)

(* ── Signal generation tests ── *)

let test_signals_output_length _ =
  let xs = Array.init 50 (fun i -> 170.0 +. float_of_int i *. 0.5) in
  let ys = Array.init 50 (fun i -> 25.0  +. float_of_int i *. 0.1) in
  let rows = Signals.generate_signals xs ys ~window:20 ~entry_z:1.5 in
  assert_bool "should have rows" (List.length rows > 0)

let test_signals_empty_on_short_input _ =
  let xs = [|1.0; 2.0|] in
  let ys = [|1.0; 2.0|] in
  let rows = Signals.generate_signals xs ys ~window:20 ~entry_z:1.5 in
  assert_equal [] rows

(* ── Suite ── *)

let suite =
  "statarb_tests" >::: [
    "welford_mean"             >:: test_welford_mean;
    "welford_variance"         >:: test_welford_variance;
    "welford_empty"            >:: test_welford_empty;
    "zscore_basic"             >:: test_zscore_basic;
    "zscore_zero_std"          >:: test_zscore_zero_std;
    "pearson_perfect"          >:: test_pearson_perfect;
    "pearson_negative"         >:: test_pearson_negative;
    "pearson_mismatched"       >:: test_pearson_mismatched;
    "ols_basic"                >:: test_ols_basic;
    "ols_too_short"            >:: test_ols_too_short;
    "signals_output_length"    >:: test_signals_output_length;
    "signals_empty_on_short"   >:: test_signals_empty_on_short_input;
  ]

let () = run_test_tt_main suite