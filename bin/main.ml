open Statarb

let () =
  (* Simulated price series for two correlated assets (e.g. GLD / SLV) *)
  (* In a real system these would be loaded from CSV or a market data API *)
  let xs = [|
    170.2; 171.0; 170.5; 172.3; 173.1; 172.8; 174.0; 173.5; 175.2; 176.0;
    175.5; 174.8; 176.3; 177.1; 176.5; 178.0; 177.4; 179.2; 180.0; 179.5;
    181.0; 180.3; 182.1; 181.5; 183.0; 182.4; 184.2; 183.7; 185.0; 184.5;
    186.1; 185.5; 187.3; 186.8; 188.0; 187.2; 189.1; 188.5; 190.0; 189.3;
    191.2; 190.5; 192.0; 191.4; 193.1; 192.5; 194.0; 193.3; 195.1; 194.6
  |] in
  let ys = [|
    25.1; 25.4; 25.2; 25.8; 26.0; 25.9; 26.3; 26.1; 26.7; 27.0;
    26.8; 26.5; 27.1; 27.4; 27.2; 27.8; 27.5; 28.1; 28.4; 28.2;
    28.7; 28.4; 29.0; 28.8; 29.4; 29.1; 29.7; 29.5; 30.1; 29.8;
    30.4; 30.1; 30.8; 30.5; 31.0; 30.7; 31.4; 31.1; 31.7; 31.4;
    32.0; 31.7; 32.3; 32.0; 32.7; 32.4; 33.0; 32.7; 33.3; 33.0
  |] in

  let window  = 20 in
  let entry_z = 1.5 in

  Printf.printf "StatArb Signal Engine\n";
  Printf.printf "======================\n";
  Printf.printf "Assets  : GLD / SLV (simulated)\n";
  Printf.printf "Window  : %d bars\n" window;
  Printf.printf "Entry Z : %.1f\n\n" entry_z;

  let rows = Signals.generate_signals xs ys ~window ~entry_z in

  if rows = [] then
    Printf.printf "No signals generated. Try a smaller window or lower entry_z.\n"
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
