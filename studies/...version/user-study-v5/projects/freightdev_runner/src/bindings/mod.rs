// src/bindings/mod.rs

#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(dead_code)]

include!("llama_cpp.rs");

// Wrapper around raw pointers from C
#[repr(transparent)]
pub struct PointerWrapper<T> {
    ptr: *mut T,
}

impl<T> PointerWrapper<T> {
    pub fn as_ref(&self) -> Option<&T> {
        unsafe { self.ptr.as_ref() }
    }

    pub fn as_mut(&mut self) -> Option<&mut T> {
        unsafe { self.ptr.as_mut() }
    }

    pub fn is_null(&self) -> bool {
        self.ptr.is_null()
    }
}
