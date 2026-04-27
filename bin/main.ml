let read_prices filename =
  let ic = open_in filename in
  let _header = input_line ic in
  let xs = ref [] in
  let ys = ref [] in
  (try
    while true do
      let line = input_line ic in
      match String.split_on_char ',' line with
      | [_date; gld; slv] ->
        xs := float_of_string (String.trim gld) :: !xs;
        ys := float_of_string (String.trim slv) :: !ys
      | _ -> ()
    done
  with End_of_file -> ());
  close_in ic;
  (Array.of_list (List.rev !xs),
   Array.of_list (List.rev !ys))

let () =
  let prices_path = "data/prices.csv" in
  let (xs, ys) = read_prices prices_path in

  let window  = 30 in
  let entry_z = 1.5 in

  Printf.printf "StatArb Signal Engine\n";
  Printf.printf "======================\n";
  Printf.printf "Assets  : GLD / SLV (real data)\n";
  Printf.printf "Bars    : %d\n" (Array.length xs);
  Printf.printf "Window  : %d bars\n" window;
  Printf.printf "Entry Z : %.1f\n\n" entry_z;

  let rows = Signals.generate_signals xs ys ~window ~entry_z in

  if rows = [] then
    Printf.printf "No signals generated.\n"
  else begin
    Printf.printf "%-6s %-12s %-10s %-6s %-10s\n"
      "Index" "Spread" "Z-Score" "Signal" "Confidence";
    Printf.printf "%s\n" (String.make 50 '-');
    List.iter (fun (r : Signals.signal_row) ->
      Printf.printf "%-6d %-12.4f %-10.4f %-6s %-10.4f\n"
        r.index r.spread r.zscore
        (Signals.string_of_signal r.signal)
        r.confidence
    ) rows;
    let csv_path = "data/signals.csv" in
    Signals.write_csv csv_path rows;
    Printf.printf "\n%s written with %d rows.\n" csv_path (List.length rows)
  end