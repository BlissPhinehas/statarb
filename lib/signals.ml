type signal = BUY | SELL | FLAT

let string_of_signal = function
  | BUY  -> "BUY"
  | SELL -> "SELL"
  | FLAT -> "FLAT"

type signal_row = {
  index      : int;
  spread     : float;
  zscore     : float;
  signal     : signal;
  confidence : float;
}

let compute_spread xs ys =
  match Stats.ols xs ys with
  | None -> None
  | Some (alpha, beta) ->
    let n = Array.length xs in
    let spread = Array.init n (fun i ->
      ys.(i) -. (alpha +. beta *. xs.(i))
    ) in
    Some (spread, alpha, beta)

let confidence z threshold =
  let ratio = (abs_float z -. threshold) /. threshold in
  if ratio < 0.0 then 0.0
  else if ratio > 1.0 then 1.0
  else ratio

let generate_signals xs ys ~window ~entry_z =
  let n = Array.length xs in
  if n <> Array.length ys || n < window then []
  else
    match compute_spread xs ys with
    | None -> []
    | Some (spread, _alpha, _beta) ->
      let rows = ref [] in
      for i = window to n - 1 do
        let slice = Array.sub spread (i - window) window in
        let state = Array.fold_left Stats.welford_update
                      Stats.welford_empty slice in
        let mean = state.Stats.mean in
        let std_opt = Stats.welford_std state in
        begin match std_opt with
        | None -> ()
        | Some std ->
          let z = Stats.zscore mean std spread.(i) in
          let sig_ =
            if z > entry_z then SELL
            else if z < -.entry_z then BUY
            else FLAT
          in
          let conf = confidence z entry_z in
          let row = {
            index      = i;
            spread     = spread.(i);
            zscore     = z;
            signal     = sig_;
            confidence = conf
          } in
          rows := row :: !rows
        end
      done;
      List.rev !rows

let write_csv filename rows =
  let oc = open_out filename in
  Printf.fprintf oc "index,spread,zscore,signal,confidence\n";
  List.iter (fun r ->
    Printf.fprintf oc "%d,%.6f,%.6f,%s,%.6f\n"
      r.index r.spread r.zscore
      (string_of_signal r.signal)
      r.confidence
  ) rows;
  close_out oc