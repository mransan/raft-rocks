module Ext = struct 
  type db 
  
  type column_family 
  
  type column_families = (string * column_family) list 
  
  type iterator 
  
  external db_open : string -> (db * column_families) 
    = "raft_rocks_db_open" 
  
  external db_create_column_family : db -> string -> column_family 
    = "raft_rocks_db_create_column_family"
  
  external db_destroy_column_family : db -> column_family -> unit 
    = "raft_rocks_db_destroy_column_family"
  
  external db_put : db -> column_family -> bytes -> bytes -> unit 
    = "raft_rocks_db_put"
  
  external db_get : db -> column_family -> bytes -> bytes 
    = "raft_rocks_db_get"
  
  external db_delete : db -> column_family -> bytes -> unit 
    = "raft_rocks_db_delete"
  
  external db_new_iterator : db -> column_family -> iterator 
    = "raft_rocks_db_new_iterator" 
  
  external iterator_valid : iterator -> bool = "raft_rocks_iterator_valid"
  
  external iterator_seek_to_first : iterator -> unit 
    = "raft_rocks_iterator_seek_to_first"
  
  external iterator_next : iterator -> unit 
    = "raft_rocks_iterator_next" 
  
  external iterator_key : iterator -> bytes
    = "raft_rocks_iterator_key" 
  
  external iterator_value : iterator -> bytes
    = "raft_rocks_iterator_value" 

end (* Ext *)

type db = {
  db : Ext.db; 
  cfs : Ext.column_families; 
  by_index_cf : Ext.column_family; 
}

let init name = 
  let db, cfs = Ext.db_open name in 

  let cfs, by_index_cf = 
    match List.assoc "by_index" cfs with
    | cf -> (cfs, cf)
    | exception Not_found ->
      let cf = Ext.db_create_column_family db "by_index" in 
      (("by_index", cf) :: cfs, cf)  
  in 

  List.iter (fun (_, cf) -> 
    Gc.finalise (fun cf -> Ext.db_destroy_column_family db cf) cf
  ) cfs; 
  
  {db; cfs; by_index_cf}

let make_index_key index = 
  let buff = Bytes.create 4 in 
  EndianBytes.BigEndian.set_int32 buff 0 (Int32.of_int index); 
  buff

let put_value db cf key value = 
  let value = 
    let encoder = Pbrt.Encoder.create () in 
    Raft_rocks_pb.encode_value value encoder; 
    Pbrt.Encoder.to_bytes encoder 
  in 

  Ext.db_put db cf key value 

let add_log ~log ~committed ?result ~db () = 

  let { Raft_log.index; term; data; id; } = log in 

  let value = Raft_rocks_pb.({
    term; id; data; committed; result;
  })  in 
  
  let {db; by_index_cf; _ } = db in 

  let key = make_index_key index in 

  put_value db by_index_cf key value 

let get_by_index ~index ~db () = 
  let key = make_index_key index in 
  let {db; by_index_cf; _} = db in 
  let value = Ext.db_get db by_index_cf key in 
  let decoder = Pbrt.Decoder.of_bytes value in 
  let {
    Raft_rocks_pb.term; 
    id; 
    committed; 
    result;
    data; 
  }  = Raft_rocks_pb.decode_value decoder  in
  ({Raft_log.index;id;term;data}, committed, result)

let set_committed_by_index ~index ~db () = 
  let key = make_index_key index in 
  let {db; by_index_cf; _} = db in 
  let value = 
    Ext.db_get db by_index_cf key 
    |> Pbrt.Decoder.of_bytes 
    |> Raft_rocks_pb.decode_value 
  in 
  if value.Raft_rocks_pb.committed
  then () (* already committed *)
  else 
    let value = {value with Raft_rocks_pb.committed = true; } in 
    put_value db by_index_cf key value 

let set_result_by_index ~index ~result ~db () = 
  let key = make_index_key index in 
  let {db; by_index_cf; _} = db in 
  let value = 
    Ext.db_get db by_index_cf key 
    |> Pbrt.Decoder.of_bytes 
    |> Raft_rocks_pb.decode_value 
  in 
  let value = {value with Raft_rocks_pb.result = Some result} in
  put_value db by_index_cf key value 

let delete_by_index ~index ~db () = 
  let key = make_index_key index in 
  let {db; by_index_cf; _} = db in 
  Ext.db_delete db by_index_cf key 

let forward_by_index ~db ~f () =  

  let {db; by_index_cf; _} = db in 
  let it = Ext.db_new_iterator db by_index_cf in 
  Ext.iterator_seek_to_first it; 

  let rec aux () = 
    if Ext.iterator_valid it 
    then begin 
      let index = 
        EndianBytes.BigEndian.get_int32 (Ext.iterator_key it) 0 
        |> Int32.to_int
      in 
      let value = 
        Ext.iterator_value it 
        |> Pbrt.Decoder.of_bytes 
        |> Raft_rocks_pb.decode_value 
      in 
      let {Raft_rocks_pb.id; term; data; committed; result; } = value in 
      let log = Raft_log.({index; id; term; data}) in 
      f log committed result; 
      Ext.iterator_next it; 
      aux ()
    end 
    else ()  
  in 
  aux () 

(* 
 * data: term; id; data; committed; result
 * add_log_record
 * update_committed_by_index
 * update_result_by_index 
 * get_by_index 
 * get_by_id 
 * iter_forward_index
 * iter_backard_index
 * delete_by_index 
 *)
