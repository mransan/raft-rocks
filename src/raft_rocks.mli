
type db 

val init : string -> db 

val add_log : 
  log : Raft_log.log_entry ->
  committed : bool ->
  ?result : bytes -> 
  db : db -> 
  unit -> 
  unit  

val get_by_index : 
 index : int -> 
 db : db -> 
 unit -> 
 (Raft_log.log_entry * bool * bytes option) 

val set_committed_by_index : 
  index : int -> 
  db : db -> 
  unit -> 
  unit 

val set_result_by_index : 
 index : int -> 
 result : bytes -> 
 db : db -> 
 unit -> 
 unit 

val delete_by_index : 
  index : int -> 
  db : db ->
  unit -> 
  unit 

val forward_by_index : 
  db : db ->
  f : (Raft_log.log_entry -> bool -> bytes option -> unit) -> 
  unit ->
  unit 
  

