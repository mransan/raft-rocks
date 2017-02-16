type db 

type column_family 

type column_families = (string * column_family) list 

external db_open : string -> (db * column_families) 
  = "raft_rocks_db_open" 

external db_create_column_family : db -> string -> column_family 
  = "raft_rocks_db_create_column_family"

external db_default_column_family_name : unit -> string 
  = "raft_rocks_db_default_column_family_name" 

external db_destroy_column_family : db -> column_family -> unit 
  = "raft_rocks_db_destroy_column_family"

external db_get_name : db -> string = "raft_rocks_db_get_name"

external db_put : db -> column_family -> string -> string -> unit 
  = "raft_rocks_db_put"

external db_get : db -> column_family -> string -> string 
  = "raft_rocks_db_get"

external db_delete : db -> column_family -> string -> unit 
  = "raft_rocks_db_delete"

type iterator 

external db_new_iterator : db -> column_family -> iterator 
  = "raft_rocks_db_new_iterator" 

external iterator_valid : iterator -> bool = "raft_rocks_iterator_valid"

external iterator_seek_to_first : iterator -> unit 
  = "raft_rocks_iterator_seek_to_first"

external iterator_next : iterator -> unit = "raft_rocks_iterator_next" 

external iterator_key : iterator -> string = "raft_rocks_iterator_key" 

external iterator_value : iterator -> string = "raft_rocks_iterator_value" 

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
