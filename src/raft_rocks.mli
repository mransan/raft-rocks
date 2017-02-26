(** Storage system for RAFT protocol using RocksDB *)

(** {2 Types} *)

(** Database handle *)
type db 

(** {2 Creators} *)

val init : string -> db 
(** [init directory_name] initialize the database in the [directory_name]. 
    If the database does not exist, then it will be created. *) 

(** {2 Upsert API} *)

val add_log : 
  log : Raft_log.log_entry ->
  committed : bool ->
  ?result : bytes -> 
  db : db -> 
  unit -> 
  unit  
(** [add_log ~log ~committed ~db ()] permenantly stores [log] with 
    [committed] attribute. *)

val set_committed_by_index : 
  index : int -> 
  db : db -> 
  unit -> 
  unit 
(** [set_committed_by_index ~index ~db ()] update the committed attribute
    of the log entry identified by [index]. @raises [Not_found] if no 
    log entry could be found. *)

val set_result_by_index : 
 index : int -> 
 result : bytes -> 
 db : db -> 
 unit -> 
 unit 
(** [set_result_by_index ~index ~result ~db ()] updates the log entry with
    its result. @raises [Not_found] if no log entry could be found *)

val delete_by_index : 
  index : int -> 
  db : db ->
  unit -> 
  unit 
(** [delete_by_index ~index ~db ()] deletes the log entry identified by 
    [index]. *)

(** {2 Accessors API} *)

type record = Raft_log.log_entry * bool * bytes option
(** The record stored for each log entry *)

val get_by_index : 
 index : int -> 
 db : db -> 
 unit -> 
 record 
(** [get_by_index ~inde ~db ()] returns the log entry identified by [index]
    in [db]. @raises [Not_found] exception if no log entry could be found *)


(** iterator type *)
type iterator = 
  | Value of record * iterator_k
  | End 
and iterator_k = (unit -> iterator) 

val forward_by_index : db : db -> unit -> iterator  
(** [forward_by_index ~db ()] returns an iterator over all the log entry
    records sorted by index *)

val backward_by_index : db : db -> unit -> iterator  
(** [backward_by_index ~db ()] returns an iterator over all the log entry
    records in reverse order of index value*)
