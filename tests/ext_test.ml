module R = Raft_rocks

let init_db name = 
  let db, cfs = R.db_open name in 

  let cfs = 
    match List.assoc "by_index" cfs with
    | h -> cfs
    | exception Not_found ->
      let handle  = R.db_create_column_family db "by_index" in 
      ("by_index", handle) :: cfs 
  in 
  List.iter (fun (_, cf) -> 
    Gc.finalise (fun cf -> R.db_destroy_column_family db cf) cf
  ) cfs; 
  
  (db, cfs) 


let () = 
  let db, cfs = init_db "test.rock" in 
  assert(2 = List.length cfs); 
  let cf = List.assoc "by_index" cfs in 

  Printf.printf "DB is: %s\n" (R.db_get_name db);
  R.db_put db cf "key0" "value0";
  Printf.printf "Val is: %s\n" (R.db_get db cf "key0");
  begin match R.db_get db cf "key1" with
  | _ -> assert(false)
  | exception Not_found -> print_endline "Val not found"
  end;
  R.db_delete db cf "key0"; 
  begin match R.db_get db cf "key0" with
  | _ -> assert(false)
  | exception Not_found -> print_endline "Val not found"
  end;

  for i = 0 to 10_000_000 do
    if i mod 100_000 = 0 then begin Printf.printf ">>  %10i\n%!" i end;
    let key = Printf.sprintf "key%10i" i in 
    let value = Printf.sprintf "val%10i" i in 
    R.db_put db cf key value; 
  done; 

  let iterator = R.db_new_iterator db cf in
  assert(not (R.iterator_valid iterator));

  R.iterator_seek_to_first iterator; 

  assert(R.iterator_valid iterator); 

  let rec aux i = 
    if R.iterator_valid iterator 
    then begin 
      if i mod 100_000  = 0 
      then begin 
        Printf.printf "(key: %s, value: %s)\n%!" 
            (R.iterator_key iterator) (R.iterator_value iterator);
      end; 
      R.iterator_next iterator; 
      aux (i + 1) 
    end 
    else ()  
  in 
  aux 0; 
  ()
