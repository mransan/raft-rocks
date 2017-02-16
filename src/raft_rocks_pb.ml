[@@@ocaml.warning "-27-30-39"]

type value = {
  term : int;
  id : string;
  data : bytes;
  committed : bool;
  result : bytes option;
}

and value_mutable = {
  mutable term : int;
  mutable id : string;
  mutable data : bytes;
  mutable committed : bool;
  mutable result : bytes option;
}

let rec default_value 
  ?term:((term:int) = 0)
  ?id:((id:string) = "")
  ?data:((data:bytes) = Bytes.create 0)
  ?committed:((committed:bool) = false)
  ?result:((result:bytes option) = None)
  () : value  = {
  term;
  id;
  data;
  committed;
  result;
}

and default_value_mutable () : value_mutable = {
  term = 0;
  id = "";
  data = Bytes.create 0;
  committed = false;
  result = None;
}

let rec decode_value d =
  let v = default_value_mutable () in
  let committed_is_set = ref false in
  let data_is_set = ref false in
  let id_is_set = ref false in
  let term_is_set = ref false in
  let rec loop () = 
    match Pbrt.Decoder.key d with
    | None -> (
    )
    | Some (1, Pbrt.Varint) -> (
      v.term <- Pbrt.Decoder.int_as_varint d; term_is_set := true;
      loop ()
    )
    | Some (1, pk) -> raise (
      Protobuf.Decoder.Failure (Protobuf.Decoder.Unexpected_payload ("Message(value), field(1)", pk))
    )
    | Some (2, Pbrt.Bytes) -> (
      v.id <- Pbrt.Decoder.string d; id_is_set := true;
      loop ()
    )
    | Some (2, pk) -> raise (
      Protobuf.Decoder.Failure (Protobuf.Decoder.Unexpected_payload ("Message(value), field(2)", pk))
    )
    | Some (3, Pbrt.Bytes) -> (
      v.data <- Pbrt.Decoder.bytes d; data_is_set := true;
      loop ()
    )
    | Some (3, pk) -> raise (
      Protobuf.Decoder.Failure (Protobuf.Decoder.Unexpected_payload ("Message(value), field(3)", pk))
    )
    | Some (4, Pbrt.Varint) -> (
      v.committed <- Pbrt.Decoder.bool d; committed_is_set := true;
      loop ()
    )
    | Some (4, pk) -> raise (
      Protobuf.Decoder.Failure (Protobuf.Decoder.Unexpected_payload ("Message(value), field(4)", pk))
    )
    | Some (5, Pbrt.Bytes) -> (
      v.result <- Some (Pbrt.Decoder.bytes d);
      loop ()
    )
    | Some (5, pk) -> raise (
      Protobuf.Decoder.Failure (Protobuf.Decoder.Unexpected_payload ("Message(value), field(5)", pk))
    )
    | Some (_, payload_kind) -> Pbrt.Decoder.skip d payload_kind; loop ()
  in
  loop ();
  begin if not !committed_is_set then raise Protobuf.Decoder.(Failure (Missing_field "committed")) end;
  begin if not !data_is_set then raise Protobuf.Decoder.(Failure (Missing_field "data")) end;
  begin if not !id_is_set then raise Protobuf.Decoder.(Failure (Missing_field "id")) end;
  begin if not !term_is_set then raise Protobuf.Decoder.(Failure (Missing_field "term")) end;
  let v:value = Obj.magic v in
  v

let rec encode_value (v:value) encoder = 
  Pbrt.Encoder.key (1, Pbrt.Varint) encoder; 
  Pbrt.Encoder.int_as_varint v.term encoder;
  Pbrt.Encoder.key (2, Pbrt.Bytes) encoder; 
  Pbrt.Encoder.string v.id encoder;
  Pbrt.Encoder.key (3, Pbrt.Bytes) encoder; 
  Pbrt.Encoder.bytes v.data encoder;
  Pbrt.Encoder.key (4, Pbrt.Varint) encoder; 
  Pbrt.Encoder.bool v.committed encoder;
  (
    match v.result with 
    | Some x -> (
      Pbrt.Encoder.key (5, Pbrt.Bytes) encoder; 
      Pbrt.Encoder.bytes x encoder;
    )
    | None -> ();
  );
  ()

let rec pp_value fmt (v:value) = 
  let pp_i fmt () =
    Format.pp_open_vbox fmt 1;
    Pbrt.Pp.pp_record_field "term" Pbrt.Pp.pp_int fmt v.term;
    Pbrt.Pp.pp_record_field "id" Pbrt.Pp.pp_string fmt v.id;
    Pbrt.Pp.pp_record_field "data" Pbrt.Pp.pp_bytes fmt v.data;
    Pbrt.Pp.pp_record_field "committed" Pbrt.Pp.pp_bool fmt v.committed;
    Pbrt.Pp.pp_record_field "result" (Pbrt.Pp.pp_option Pbrt.Pp.pp_bytes) fmt v.result;
    Format.pp_close_box fmt ()
  in
  Pbrt.Pp.pp_brk pp_i fmt ()
