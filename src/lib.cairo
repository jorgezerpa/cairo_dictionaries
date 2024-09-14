// dictionaries, objects, hash maps, associative arrays, etc
// key -> value   
// keys are unique 

use core::dict::{Felt252Dict, Felt252DictEntryTrait};
use core::nullable::{NullableTrait, match_nullable, FromNullableResult};

fn main() {
    let mut balances: Felt252Dict<u64> = Default::default(); // Default create a new instance of Felt252Dict<u64> 

    balances.insert('Capibara', 100);
    balances.insert('Tapire', 200);
    balances.insert('Capibara', 300); // simulating a mutable memory

    let capibara_balance = balances.get('Capibara');
    let unexistant_balance = balances.get('Chicken');
    assert!(capibara_balance == 300, "Balance of Capibara is not 300");
    assert!(unexistant_balance == 0, "This has balance!"); // by default, all is 0 (no return error) --> So, you can NOT delete data from a dic

    // GOING DEEP -> how does this work under the hood?

    // Felt252Dict<T> is a list of entries
    // a list of entries has -> key, previous_value, new_value
    ////// This is an entry --> (later we will check structs)
    // struct Entry<T> {
    //     key: felt252,
    //     previous_value: T,
    //     new_value: T,
    // }
    ////// This is a dict -> [Entry, Entry, Entry]
    /// // so dicts are equal to -> Array<Entry<T>>
    /// 
    /// A get would register an entry where there is no change in state, and previous and new values are stored with the same value.
    /// An insert would register a new Entry<T> where the new_value would be the element being inserted, and the previous_value the last element inserted before this.
    //  (imagine a table with key, previous nad new headers) 


    // Entry and finalize -> replicating get and insert
    // GET

    let mut new_dict: Felt252Dict<u64> = Default::default();
    println!("{}", new_dict.get('cat'));
    let (entry, prev_value) = new_dict.entry('cat');  // returns (last_entry, entry_value --> this method takes the ownership of the dictionary
    let mut new_dict = entry.finalize(prev_value); // return the dict updated
    println!("{}", new_dict.get('cat'));
    // custom_get
    // INSERT
    let mut new_dict: Felt252Dict<u64> = Default::default();
    println!("{}", new_dict.get('cat'));
    let (entry, _) = new_dict.entry('cat');  // returns (last_entry, entry_value --> this method takes the ownership of the dictionary
    let new_value = 4;
    let mut new_dict = entry.finalize(new_value); // return the dict updated
    println!("{}", new_dict.get('cat'));
    // custom_insert


    // Using not native supported types
    let mut dict:Felt252Dict<Nullable<Span<u64>>> = Default::default();
    let a = array![8, 9, 10];
    dict.insert(0, NullableTrait::new(a.span()));

    let value = dict.get(0);
    let span = match match_nullable(value){
        FromNullableResult::Null => panic!("No value found"),
        FromNullableResult::NotNull(val) => val.unbox(),
    };
    println!("span dict first value -> {}", span.at(0));



    // Dicts and arrays manipulation 
    let arr = array![20, 19, 26];
    let mut dict:Felt252Dict<Nullable<Array<u8>>> = Default::default();
    dict.insert(0, NullableTrait::new(arr));
    // dict.get(0); // this line will fail because of no copy trait on arrays 
    // correct way to read an array
    let (entry, _arr) = dict.entry(0);
    let mut arr = _arr.deref_or(array![]); // here is your array, do what you want
    dict = entry.finalize(NullableTrait::new(arr));

    // modifying the array 
    let (entry, arr) = dict.entry(0);
    let mut unboxed_val = arr.deref_or(array![]);
    unboxed_val.append(5);
    dict = entry.finalize(NullableTrait::new(unboxed_val));



}


fn custom_get<T, +Felt252DictValue<T>, +Drop<T>, +Copy<T>>(
    ref dict: Felt252Dict<T>, entry:felt252
) -> T {
    let (entry, prev_value) = dict.entry(entry);
    dict = entry.finalize(prev_value);
    prev_value
}

fn custom_insert<T, +Felt252DictValue<T>, +Destruct<T>, +Drop<T>>(
    ref dict: Felt252Dict<T>, key: felt252, value: T
) {
    let (entry, _prev_value) = dict.entry(key);
    dict = entry.finalize(value);
}

fn get_array_entry(ref dict: Felt252Dict<Nullable<Array<u8>>>, index: felt252) -> Span<u8> {
    let (entry, _arr) = dict.entry(index);
    let mut arr = _arr.deref_or(array![]);
    let span = arr.span();
    dict = entry.finalize(NullableTrait::new(arr));
    span
}
