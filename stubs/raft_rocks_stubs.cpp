#ifndef RAFT_ROCKS_STUBS_CPP 
#define RAFT_ROCKS_STUBS_CPP 

#include "caml/mlvalues.h"
#include "caml/memory.h" 
#include "caml/alloc.h"
#include "caml/custom.h"
#include "caml/fail.h"

#include "rocksdb/db.h"

#include <string>
#include <cstring>
#include <iostream>

/****************************************/
/*      rocksdb::DB* Custom Value       */
/****************************************/

#define Raft_rocks_db_val(v) (*((rocksdb::DB**)(Data_custom_val(v)))) 

static void raft_rocks_db_ops_finalize(value ml_db) {
  delete Raft_rocks_db_val(ml_db); 
}

static struct custom_operations db_ops= {
  (char*)("raft_rocks_db_ops"),
  raft_rocks_db_ops_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value raft_rocks_db_alloc(rocksdb::DB* db) {
  CAMLparam0(); 
  CAMLlocal1(ml_db); 
  ml_db = caml_alloc_custom(&db_ops, sizeof(rocksdb::DB*), 1, 1); 
  Raft_rocks_db_val(ml_db) = db; 
  CAMLreturn(ml_db);
}

/***************************************************/
/*    rocksdb::ColumnFamilyHandle* Custom Value    */
/***************************************************/

#define Raft_rocks_cf_val(v) \
  (*((rocksdb::ColumnFamilyHandle**)(Data_custom_val(v)))) 

static struct custom_operations cf_ops = {
  (char*)("raft_rocks_cf_ops"),
  custom_finalize_default,
    // The OCAML side needs to register the finalizer which will 
    // call the DB member function to destroy the handle
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value raft_rocks_cf_alloc(rocksdb::ColumnFamilyHandle* cf) {
  CAMLparam0(); 
  CAMLlocal1(ml_cf); 
  ml_cf = caml_alloc_custom(&cf_ops, 
                            sizeof(rocksdb::ColumnFamilyHandle*), 1, 1); 
  Raft_rocks_cf_val(ml_cf) = cf; 
  CAMLreturn(ml_cf);
}

/*****************************************/
/*    rocksdb::Iterator* Custom Value    */
/*****************************************/

#define Raft_rocks_iterator_val(v) \
  (*((rocksdb::Iterator**)(Data_custom_val(v)))) 

static void raft_rocks_iterator_ops_finalize(value ml_iterator) {
  delete Raft_rocks_iterator_val(ml_iterator); 
}

static struct custom_operations iterator_ops= {
  (char*)("raft_rocks_iterator_ops"),
  raft_rocks_iterator_ops_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value raft_rocks_iterator_alloc(rocksdb::Iterator* iterator) {
  CAMLparam0(); 
  CAMLlocal1(ml_iterator); 
  ml_iterator = caml_alloc_custom(&iterator_ops, 
                                  sizeof(rocksdb::Iterator*), 1, 1); 
  Raft_rocks_iterator_val(ml_iterator) = iterator; 
  CAMLreturn(ml_iterator);
}

/*******************************/
/*    List Utilities           */
/*******************************/

static value raft_rocks_cons(value l, value v) {
  CAMLparam2(l, v); 
  CAMLlocal1(e); 
  e = caml_alloc(2, 0); 
  Store_field(e, 0, v); 
  Store_field(e, 1, l); 
  CAMLreturn(e); 
}

extern "C" value raft_rocks_db_open(value ml_name) {
  CAMLparam1(ml_name); 
  CAMLlocal4(ml_db,        // db pointer 
             ml_cf_list,   // list of (column family name, handle) 
             ml_cf_list_e, // tmp variable for creating pairs 
             ml_ret);      // return value pair of db handle and list of cf

  rocksdb::Status st;
  {
    std::string name(String_val(ml_name)); 

    rocksdb::DBOptions db_options; 
    db_options.create_if_missing = true; 

    // get the names of column families
    std::vector<std::string> cf_names; 
    st = rocksdb::DB::ListColumnFamilies(db_options, name, &cf_names); 
    if(st.IsIOError()) {
      // looks like the ListColumnFamilies fails if the DB is not created
      // 
      cf_names = std::vector<std::string>(1, rocksdb::kDefaultColumnFamilyName); 
    }
    else if(! st.ok()) { goto end; }

    // transform names into descriptors
    std::vector<rocksdb::ColumnFamilyDescriptor> cf_descriptors; 
    for(auto const& cf_name : cf_names) {
      cf_descriptors.push_back(
            rocksdb::ColumnFamilyDescriptor(
                cf_name, rocksdb::ColumnFamilyOptions()));  
    }

    std::vector<rocksdb::ColumnFamilyHandle*> cf_handles;
              
    rocksdb::DB* db = nullptr;; 
    st = rocksdb::DB::Open(db_options, 
                           name, 
                           cf_descriptors, 
                           &cf_handles, 
                           &db);
    if(! st.ok()) { goto end; } 

    ml_db = raft_rocks_db_alloc(db);

    // transform the vector for handles to a list of pairs
    //     (column family name, column family handle)
    //
    ml_cf_list = Val_int(0); // empty list []
    for(auto cf_handle : cf_handles) {
      ml_cf_list_e = caml_alloc(2, 0); 
      Store_field(ml_cf_list_e, 0, 
                  caml_copy_string(cf_handle->GetName().c_str())); 
      Store_field(ml_cf_list_e, 1, 
                  raft_rocks_cf_alloc(cf_handle)); 

      ml_cf_list = raft_rocks_cons(ml_cf_list, ml_cf_list_e);
    }
  }

end: 
  if(! st.ok()) {
    std::string msg(st.ToString()); 
    caml_failwith(msg.c_str()); 
  } 

  ml_ret = caml_alloc(2, 0); 
  Store_field(ml_ret, 0, ml_db); 
  Store_field(ml_ret, 1, ml_cf_list);

  CAMLreturn(ml_ret);
} 

extern "C" value raft_rocks_db_create_column_family(value ml_db, 
                                                    value ml_name) {
  CAMLparam2(ml_db, ml_name); 
  CAMLlocal1(ml_cf); 

  rocksdb::Status st;
  {
    rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
    rocksdb::ColumnFamilyHandle* cf = nullptr;
    rocksdb::ColumnFamilyOptions options;
    std::string name(String_val(ml_name)); 
    st = db->CreateColumnFamily(options, name, &cf); 
    if(! st.ok()) { goto end; }
    ml_cf = raft_rocks_cf_alloc(cf);
  }
end:
  if(! st.ok()) {
    std::string msg(st.ToString()); 
    caml_failwith(msg.c_str()); 
  } 

  CAMLreturn(ml_cf);
}

extern "C" value raft_rocks_db_destroy_column_family(value ml_db, value ml_cf){
  CAMLparam2(ml_db, ml_cf); 

  rocksdb::Status st;
  {
    rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
    rocksdb::ColumnFamilyHandle* cf = Raft_rocks_cf_val(ml_cf); 
    rocksdb::Status st = db->DestroyColumnFamilyHandle(cf); 
  }
  if(! st.ok()) {
    std::string msg(st.ToString()); 
    caml_failwith(msg.c_str()); 
  }

  CAMLreturn(Val_unit);
} 

extern "C" value raft_rocks_db_put(value ml_db, value ml_cf, 
                                   value ml_key, value ml_val) {
  CAMLparam4(ml_db, ml_cf, ml_key, ml_val); 

  rocksdb::Status st;
  {
    rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
    rocksdb::ColumnFamilyHandle* cf = Raft_rocks_cf_val(ml_cf); 
    rocksdb::Slice key(String_val(ml_key), caml_string_length(ml_key)); 
    rocksdb::Slice val(String_val(ml_val), caml_string_length(ml_val)); 
    rocksdb::WriteOptions options; 

    st = db->Put(options, cf, key, val); 
  }
  if(! st.ok()) {
    std::string msg(st.ToString());
    caml_failwith(msg.c_str());
  }

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_db_get(value ml_db, value ml_cf, value ml_key) {
  CAMLparam3(ml_db, ml_cf, ml_key); 
  CAMLlocal1(ml_val);

  rocksdb::Status st; 
  {
    rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
    rocksdb::ColumnFamilyHandle* cf = Raft_rocks_cf_val(ml_cf); 
    rocksdb::Slice key(String_val(ml_key), caml_string_length(ml_key)); 
    rocksdb::ReadOptions options; 

    std::string val; 
    st = db->Get(options, cf, key, &val); 
    if(! st.ok()) { goto end; }
    ml_val = caml_alloc_string(val.size()); 
    ::memcpy(String_val(ml_val), val.c_str(), val.size());
  }
end: 
  if(! st.ok()) {
    if(st.IsNotFound()) {
      caml_raise_not_found(); 
    }
    else {
      std::string msg(st.ToString());
      caml_failwith(msg.c_str());
    }
  }

  CAMLreturn(ml_val);
}

extern "C" value raft_rocks_db_delete(value ml_db, value ml_cf, value ml_key) {
  CAMLparam3(ml_db, ml_cf, ml_key); 

  rocksdb::Status st;
  {
    rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
    rocksdb::ColumnFamilyHandle* cf = Raft_rocks_cf_val(ml_cf); 
    rocksdb::Slice key(String_val(ml_key), caml_string_length(ml_key)); 
    rocksdb::WriteOptions options; 

    rocksdb::Status st = db->Delete(options, cf, key); 
  }
  if(! st.ok()) {
    std::string msg(st.ToString());
    caml_failwith(msg.c_str());
  }

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_db_new_iterator(value ml_db, value ml_cf) {
  CAMLparam2(ml_db, ml_cf); 
  CAMLlocal1(ml_iterator);

  rocksdb::DB* db = Raft_rocks_db_val(ml_db); 
  rocksdb::ColumnFamilyHandle* cf = Raft_rocks_cf_val(ml_cf); 
  rocksdb::ReadOptions options;
  rocksdb::Iterator* iterator = db->NewIterator(options, cf); 

  ml_iterator = raft_rocks_iterator_alloc(iterator); 
  CAMLreturn(ml_iterator);
}

extern "C" value raft_rocks_iterator_valid(value ml_iterator) {
  CAMLparam1(ml_iterator); 
  CAMLlocal1(ml_is_valid);

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  ml_is_valid = Val_bool(iterator->Valid()); 

  CAMLreturn(ml_is_valid);
}

extern "C" value raft_rocks_iterator_seek_to_first(value ml_iterator) {
  CAMLparam1(ml_iterator); 

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  iterator->SeekToFirst();

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_iterator_seek_to_last(value ml_iterator) {
  CAMLparam1(ml_iterator); 

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  iterator->SeekToLast();

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_iterator_next(value ml_iterator) {
  CAMLparam1(ml_iterator); 

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  iterator->Next();

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_iterator_prev(value ml_iterator) {
  CAMLparam1(ml_iterator); 

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  iterator->Prev();

  CAMLreturn(Val_unit);
}

extern "C" value raft_rocks_iterator_key(value ml_iterator) {
  CAMLparam1(ml_iterator); 
  CAMLlocal1(ml_key);

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  rocksdb::Slice key = iterator->key();

  ml_key = caml_alloc_string(key.size());
  ::memcpy(String_val(ml_key), key.data(), key.size()); 

  CAMLreturn(ml_key);
}

extern "C" value raft_rocks_iterator_value(value ml_iterator) {
  CAMLparam1(ml_iterator); 
  CAMLlocal1(ml_value);

  rocksdb::Iterator* iterator = Raft_rocks_iterator_val(ml_iterator);
  rocksdb::Slice value_ = iterator->value();

  ml_value = caml_alloc_string(value_.size());
  ::memcpy(String_val(ml_value), value_.data(), value_.size()); 

  CAMLreturn(ml_value);
}

#endif 
