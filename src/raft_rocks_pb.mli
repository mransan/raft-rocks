(** raft_rocks.proto Generated Types and Encoding *)


(** {2 Types} *)

type value = {
  term : int;
  id : string;
  data : bytes;
  committed : bool;
  result : bytes option;
}


(** {2 Default values} *)

val default_value : 
  ?term:int ->
  ?id:string ->
  ?data:bytes ->
  ?committed:bool ->
  ?result:bytes option ->
  unit ->
  value
(** [default_value ()] is the default value for type [value] *)


(** {2 Protobuf Decoding} *)

val decode_value : Pbrt.Decoder.t -> value
(** [decode_value decoder] decodes a [value] value from [decoder] *)


(** {2 Protobuf Toding} *)

val encode_value : value -> Pbrt.Encoder.t -> unit
(** [encode_value v encoder] encodes [v] with the given [encoder] *)


(** {2 Formatters} *)

val pp_value : Format.formatter -> value -> unit 
(** [pp_value v] formats v *)
