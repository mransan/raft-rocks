
let () = 
  let db = Raft_rocks.init "test.rocks" in 

  let log = Raft_log.({
    index = 1; 
    term = 1; 
    id = "this is a test id"; 
    data = Bytes.of_string "this is a test data"; 
  }) in  

  let committed = false in 

  Raft_rocks.add_log ~log ~committed ~db (); 

  let log', committed, result = Raft_rocks.get_by_index ~index:1 ~db () in 
  assert(log = log'); 
  assert(not committed); 
  assert(None = result);

  Raft_rocks.set_committed_by_index ~index:1 ~db (); 
  
  let log', committed, result = Raft_rocks.get_by_index ~index:1 ~db () in 
  assert(log = log'); 
  assert(committed); 
  assert(None = result); 

  let result = Bytes.of_string "this is the test result" in 
  Raft_rocks.set_result_by_index ~index:1 ~result ~db (); 

  let log', committed, result' = Raft_rocks.get_by_index ~index:1 ~db () in 
  assert(log = log'); 
  assert(committed); 
  assert(Some result = result'); 

  Raft_rocks.forward_by_index ~db ~f:(fun log' committed result' -> 
    assert(log = log'); 
    assert(committed); 
    assert(Some result = result'); 
  ) (); 

  Raft_rocks.delete_by_index ~index:1 ~db (); 

  begin match Raft_rocks.get_by_index ~index:1 ~db () with
  | _ -> assert(false) 
  | exception Not_found -> ()
  end; 

  Raft_rocks.forward_by_index ~db ~f:(fun _ _ _ -> 
    assert(false); 
  ) ();  
  
  ()
